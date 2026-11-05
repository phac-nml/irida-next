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
        before_create :write_traversal_ids
        before_update :set_traversal_ids, if: :will_save_change_to_parent_id?
        after_update :sync_descendants_traversal_ids, if: :saved_change_to_parent_id?
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

      # Set traversal_ids for a namespace before it is inserted. Runs
      # before_create (rather than after) so that `traversal_ids` is part of
      # the original INSERT instead of a separate UPDATE immediately after
      # it - a separate UPDATE would otherwise log a spurious extra logidze
      # version for every namespace creation. The primary key is normally
      # assigned by the database default (`gen_random_uuid()`), which only
      # happens once the row is inserted, so it is generated here in Ruby
      # instead, to have it available up front for building `traversal_ids`.
      def write_traversal_ids
        self.id ||= SecureRandom.uuid
        self.traversal_ids = (parent&.traversal_ids || []) + [id]
      end

      # Set traversal_ids for a namespace that is about to be reparented.
      # Runs before_update (rather than after) so that `traversal_ids` is
      # part of the same UPDATE as the `parent_id` change, instead of a
      # separate UPDATE afterwards - a separate UPDATE would otherwise log a
      # spurious extra logidze version, and (more importantly) a `reload`
      # to pick up its result would clear this record's
      # `saved_changes`/`previous_changes`, which other `after_commit`
      # callbacks on this same save - e.g. `Namespace#propagate_parent_change`,
      # guarded by `if: :saved_change_to_parent_id?` - rely on to detect the
      # reparenting that just happened.
      def set_traversal_ids
        self.traversal_ids = (parent&.traversal_ids || []) + [id]
      end

      # Resync traversal_ids for this namespace's descendants after it is
      # reparented (this namespace's own `traversal_ids` was already synced
      # by `set_traversal_ids`, as part of the same UPDATE). The pre-move
      # value is read via `saved_change_to_traversal_ids` - `traversal_ids`
      # itself already holds the new, post-move value at this point - and
      # used as the prefix to match this namespace's existing subtree, which
      # is then replaced in a single UPDATE with the new prefix.
      def sync_descendants_traversal_ids
        old_prefix, new_prefix = saved_change_to_traversal_ids
        return if old_prefix.blank? || old_prefix == new_prefix

        old_ids = quoted_uuid_array(old_prefix)
        new_ids = quoted_uuid_array(new_prefix)

        # Use `Namespace.unscoped`, not `self.class.unscoped`: the affected
        # subtree (this namespace's descendants) commonly spans multiple STI
        # subtypes (e.g. a Group's descendants include
        # Namespaces::ProjectNamespace rows), and Rails always applies the
        # receiver's STI `type` condition to a query, even past `unscoped`.
        Namespace.unscoped.where.not(id:).where(
          "traversal_ids[1:cardinality(#{old_ids})] = #{old_ids}"
        ).update_all( # rubocop:disable Rails/SkipsModelValidations
          "traversal_ids = #{new_ids} || traversal_ids[(cardinality(#{old_ids}) + 1):]"
        )
      end

      def quoted_uuid_array(ids)
        "ARRAY[#{ids.map { |id| self.class.connection.quote(id) }.join(',')}]::uuid[]"
      end
    end
  end
end
