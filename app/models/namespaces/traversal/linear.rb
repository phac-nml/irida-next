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
    # Every public method here is defined under its `linear_`-prefixed name,
    # with the unprefixed name as a plain alias. This is deliberate: when
    # mixed into `Namespace` alongside `RouteBased`, whichever module is
    # `include`d last wins method-name collisions for both instance and
    # class-level (scope) methods (e.g. `#ancestors`, `#self_and_descendants`).
    # If this module's own methods called each other by their unprefixed
    # names, those internal calls would silently dispatch to the other
    # strategy's implementation once both are mixed in. Routing every
    # internal call through the `linear_`-prefixed name keeps this module
    # correct and self-contained regardless of include order.
    module Linear
      extend ActiveSupport::Concern
      include LinearScopes

      included do
        after_create :write_traversal_ids
        after_update :sync_traversal_ids, if: :saved_change_to_parent_id?
      end

      def linear_ancestors
        return self.class.none if parent_id.blank?

        linear_self_and_ancestors.where.not(id:)
      end
      alias ancestors linear_ancestors

      def linear_ancestor_ids
        linear_ancestors.linear_as_ids
      end
      alias ancestor_ids linear_ancestor_ids

      def linear_self_and_ancestors
        self.class.where(id:).linear_self_and_ancestors
      end
      alias self_and_ancestors linear_self_and_ancestors

      def linear_self_and_ancestors_of_type(types)
        linear_self_and_ancestors.where(type: types)
      end
      alias self_and_ancestors_of_type linear_self_and_ancestors_of_type

      def linear_self_and_ancestor_ids
        linear_self_and_ancestors.linear_as_ids
      end
      alias self_and_ancestor_ids linear_self_and_ancestor_ids

      def linear_descendants
        linear_self_and_descendants.where.not(id:)
      end
      alias descendants linear_descendants

      def linear_self_and_descendants
        self.class.where(id:).linear_self_and_descendants
      end
      alias self_and_descendants linear_self_and_descendants

      def linear_self_and_descendants_of_type(types)
        linear_self_and_descendants.where(type: types)
      end
      alias self_and_descendants_of_type linear_self_and_descendants_of_type

      def linear_self_and_descendant_ids
        linear_self_and_descendants.linear_as_ids
      end
      alias self_and_descendant_ids linear_self_and_descendant_ids

      private

      # Set traversal_ids for a newly created namespace. Runs after create
      # (rather than before save) because the primary key is assigned by the
      # database default (gen_random_uuid()) and is only known once the row
      # has been inserted.
      def write_traversal_ids
        update_column(:traversal_ids, (parent&.traversal_ids || []) + [id]) # rubocop:disable Rails/SkipsModelValidations
      end

      # Resync traversal_ids for this namespace and all of its descendants
      # after it is reparented. `traversal_ids` still holds the pre-move
      # value at this point (it is not touched by the parent_id update), so
      # it is used as the prefix to match this namespace's existing subtree,
      # which is then replaced in a single UPDATE with the new prefix.
      def sync_traversal_ids
        old_prefix = traversal_ids
        new_prefix = (parent&.traversal_ids || []) + [id]
        return if old_prefix == new_prefix

        old_ids = quoted_uuid_array(old_prefix)
        new_ids = quoted_uuid_array(new_prefix)

        # Use `Namespace.unscoped`, not `self.class.unscoped`: the affected
        # subtree (this namespace plus all of its descendants) commonly spans
        # multiple STI subtypes (e.g. a Group's descendants include
        # Namespaces::ProjectNamespace rows), and Rails always applies the
        # receiver's STI `type` condition to a query, even past `unscoped`.
        Namespace.unscoped.where(
          "traversal_ids[1:cardinality(#{old_ids})] = #{old_ids}"
        ).update_all( # rubocop:disable Rails/SkipsModelValidations
          "traversal_ids = #{new_ids} || traversal_ids[(cardinality(#{old_ids}) + 1):]"
        )

        reload
      end

      def quoted_uuid_array(ids)
        "ARRAY[#{ids.map { |id| self.class.connection.quote(id) }.join(',')}]::uuid[]"
      end
    end
  end
end
