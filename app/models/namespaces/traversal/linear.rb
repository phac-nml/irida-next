# frozen_string_literal: true

module Namespaces
  module Traversal
    # Provides linear (array-based) traversal helpers for namespace
    # hierarchies, using the `traversal_ids` column instead of the `routes`
    # table. `traversal_ids` stores the root-to-self chain of namespace ids
    # for every namespace, which makes ancestor lookups a simple `id IN (...)`
    # and descendant lookups a prefix comparison on the array - no joins
    # through `routes` are required.
    #
    # The `traversal_ids` column is kept in sync by the callbacks below
    # whenever a namespace is created or reparented, regardless of whether
    # this module's methods are the ones actively used for traversal.
    #
    # `Linear` is included after `RouteBased` on `Namespace`, so its bare
    # method names (`#ancestors`, `#self_and_descendants`, etc.) take
    # precedence. Each method here checks `use_traversal_ids?` first and
    # calls `super` - which resolves to `RouteBased`'s implementation of the
    # same name - whenever `traversal_ids` is blank for the namespace(s)
    # involved. This makes the fast path the default while keeping a
    # self-healing fallback: a namespace that is somehow missing
    # `traversal_ids` (e.g. inserted directly via SQL, or mid-backfill) is
    # still traversed correctly, just via the slower route-based query,
    # with no manual coordination required.
    module Linear
      extend ActiveSupport::Concern
      include LinearScopes

      included do
        after_create :write_traversal_ids
        after_update :sync_traversal_ids, if: :saved_change_to_parent_id?
      end

      # Whether this namespace's `traversal_ids` is populated and can be used
      # for the fast, array-based traversal methods below. Returns false for
      # a namespace that predates the `traversal_ids` backfill (should not
      # happen post-migration), was inserted without going through the
      # `write_traversal_ids` callback (e.g. raw SQL), or if the
      # `traversal_ids` column itself does not exist yet (e.g. mid-migration,
      # as exercised by the `AddTraversalIdsToNamespaces` migration test) -
      # in which case every method below transparently falls back to
      # `RouteBased`'s implementation via `super`.
      def use_traversal_ids?
        has_attribute?(:traversal_ids) && traversal_ids.present?
      end

      def ancestors
        return super unless use_traversal_ids?
        return self.class.none if parent_id.blank?

        self_and_ancestors.where.not(id:)
      end

      def ancestor_ids
        return super unless use_traversal_ids?

        ancestors.as_ids
      end

      # Mirrors RouteBased's semantics: the default (non-`_of_type`) ancestor
      # and descendant methods are restricted to the receiver's own STI type
      # (e.g. a Group's #descendants only includes other Groups, excluding
      # Namespaces::ProjectNamespace descendants); use the `_of_type`
      # variants to query across STI types.
      def self_and_ancestors
        return super unless use_traversal_ids?

        self_and_ancestors_of_type(self.class.sti_name)
      end

      def self_and_ancestors_of_type(types)
        return super unless use_traversal_ids?

        self.class.where(id:).self_and_ancestors_across_types.where(type: types)
      end

      def self_and_ancestor_ids
        return super unless use_traversal_ids?

        self_and_ancestors.as_ids
      end

      def descendants
        return super unless use_traversal_ids?

        self_and_descendants.where.not(id:)
      end

      def self_and_descendants
        return super unless use_traversal_ids?

        self_and_descendants_of_type(self.class.sti_name)
      end

      def self_and_descendants_of_type(types)
        return super unless use_traversal_ids?

        self.class.where(id:).self_and_descendants_across_types.where(type: types)
      end

      def self_and_descendant_ids
        return super unless use_traversal_ids?

        self_and_descendants.as_ids
      end

      private

      # Set traversal_ids for a namespace right after it is inserted. Runs
      # after_create (rather than before) so that the primary key - assigned
      # by the database default (`gen_random_uuid()`), which only exists
      # once the row is inserted - can be used directly, instead of
      # generating it in Ruby ahead of time. This requires a second UPDATE
      # statement right after the INSERT (via `update_column`, which
      # bypasses validations/callbacks and dirty tracking), so namespace
      # creation logs two logidze versions instead of one - an accepted
      # tradeoff in favour of letting the database generate the id.
      def write_traversal_ids
        update_column(:traversal_ids, (parent&.traversal_ids || []) + [id]) # rubocop:disable Rails/SkipsModelValidations
      end

      # Set traversal_ids for this namespace and resync it for all of its
      # descendants, after this namespace is reparented. Runs after_update
      # (rather than before) so the already-committed `parent_id` change (and
      # the `saved_change_to_parent_id?` guard above, and
      # `Namespace#propagate_parent_change`'s own `after_commit` guard) are
      # unaffected by this method's own writes. Because this namespace's
      # `traversal_ids` is set via a separate UPDATE (`update_column`, again
      # bypassing dirty tracking), the pre-move value is captured in
      # `old_prefix` before that write, rather than read afterwards via
      # `saved_change_to_traversal_ids` - which `update_column` would not
      # have populated.
      def sync_traversal_ids
        old_prefix = traversal_ids
        new_prefix = (parent&.traversal_ids || []) + [id]
        return if old_prefix == new_prefix

        update_column(:traversal_ids, new_prefix) # rubocop:disable Rails/SkipsModelValidations
        sync_descendants_traversal_ids(old_prefix, new_prefix)
      end

      # Resync traversal_ids for this namespace's descendants, to replace the
      # pre-move `old_prefix` (this namespace's own previous root-to-self
      # chain, matched as a prefix of each descendant's existing
      # `traversal_ids`) with the post-move `new_prefix`, in a single UPDATE.
      def sync_descendants_traversal_ids(old_prefix, new_prefix)
        return if old_prefix.blank?

        old_ids = quoted_traversal_ids(old_prefix)
        new_ids = quoted_traversal_ids(new_prefix)
        remaining_suffix_slice = array_slice_sql(old_prefix.length + 1)

        # Use `Namespace.unscoped`, not `self.class.unscoped`: the affected
        # subtree (this namespace's descendants) commonly spans multiple STI
        # subtypes (e.g. a Group's descendants include
        # Namespaces::ProjectNamespace rows), and Rails always applies the
        # receiver's STI `type` condition to a query, even past `unscoped`.
        Namespace.unscoped.where.not(id:)
                 .where(array_slice_sql(1, old_prefix.length).eq(old_ids))
                 .update_all("traversal_ids = #{Arel::Nodes::InfixOperation.new('||', new_ids, remaining_suffix_slice).to_sql}") # rubocop:disable Rails/SkipsModelValidations,Layout/LineLength
      end

      # Builds an Arel-quoted value for an array of namespace ids, cast per
      # the `traversal_ids` attribute's `uuid[]` type, rather than
      # interpolating hand-quoted SQL strings - this keeps the query safe
      # from SQL injection by construction instead of relying on manual
      # escaping.
      def quoted_traversal_ids(ids)
        Arel::Nodes.build_quoted(ids, Namespace.arel_table[:traversal_ids])
      end

      # Builds Postgres' array-slice syntax (`traversal_ids[from:to]` or
      # `traversal_ids[from:]` when `to` is omitted), which Arel has no
      # built-in node for. `from`/`to` are array indices derived from
      # `traversal_ids` lengths (not user-controlled data); coercing them with
      # `#to_i` makes this explicit so the interpolation below cannot carry
      # anything other than a plain integer.
      def array_slice_sql(from, to = nil)
        from = from.to_i
        to = to.to_i if to

        Arel.sql("traversal_ids[#{from}:#{to}]")
      end
    end
  end
end
