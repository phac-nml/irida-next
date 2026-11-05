# frozen_string_literal: true

module Namespaces
  module Traversal
    # Scopes for traversing namespace hierarchies using the `traversal_ids`
    # column (an array of the root-to-self chain of namespace ids) instead of
    # joining through the `routes` table.
    #
    # `LinearScopes` is included after `RouteBasedScopes` on `Namespace`
    # (via `Namespaces::Traversal::Linear` being included after
    # `Namespaces::Traversal::RouteBased`), so these bare-named scopes take
    # precedence and are the default. Unlike the instance-level methods in
    # `Linear`, these class-level scopes always operate on `traversal_ids`
    # directly rather than falling back per-row, since a scope spans a whole
    # relation rather than a single namespace; `RouteBasedScopes`'
    # equivalents remain reachable via their `route_based_*` aliases for any
    # caller that needs the route-based behavior explicitly.
    #
    # Like `RouteBasedScopes`, the bare `self_and_ancestors`/
    # `self_and_descendants` scopes are implicitly restricted to the
    # receiver's own STI type (e.g. `Group.where(...).self_and_descendants`
    # only returns Groups), matching Rails' default STI query behavior. The
    # `*_across_types` variants lift that restriction and are used
    # internally by `Linear`'s instance-level `_of_type` methods, which
    # explicitly query across STI types.
    module LinearScopes
      extend ActiveSupport::Concern

      class_methods do # rubocop:disable Metrics/BlockLength
        def as_ids
          select(Namespace.arel_table[:id])
        end

        # Return a relation containing the namespaces in the receiver
        # relation and all of their ancestors.
        #
        # Implementation:
        # - `traversal_ids` already stores the full root-to-self id chain for
        #   every namespace, so the ancestors (and self) of the receiver
        #   relation are simply every id that appears in any of those arrays.
        #   `unnest` expands each array into one row per id, which we then
        #   use to filter `namespaces` by primary key.
        #
        # Returns an ActiveRecord::Relation of Namespace records (self + ancestors).
        #
        # Note: like `RouteBasedScopes#self_and_ancestors`, this is scoped to
        # `unscoped` (i.e. `self.class.unscoped`), so Rails' STI `type`
        # condition for the receiver's class is preserved (e.g.
        # `Group.where(...).self_and_ancestors` only returns Groups). Use
        # `self_and_ancestors_across_types` to query across STI types.
        def self_and_ancestors
          unscoped.where(id: select(Arel.sql('unnest(namespaces.traversal_ids)')))
        end

        def self_and_ancestor_ids
          self_and_ancestors.as_ids
        end

        # Same as `#self_and_ancestors`, but queries `Namespace.unscoped`
        # instead of `unscoped`, so results are not restricted to the
        # receiver's STI type. Used internally by the instance-level
        # `#self_and_ancestors_of_type` to find ancestors of a different STI
        # type than the receiver (e.g. a Project's Group ancestors).
        def self_and_ancestors_across_types
          Namespace.unscoped.where(id: select(Arel.sql('unnest(namespaces.traversal_ids)')))
        end

        # Return a relation containing the namespaces in the receiver
        # relation and all of their descendants.
        #
        # Implementation:
        # - A namespace is a descendant of (or equal to) one of the base
        #   namespaces when its `traversal_ids`, truncated to the base
        #   namespace's depth, equals the base namespace's `traversal_ids`.
        #   This is expressed with Postgres array-slice syntax
        #   (`traversal_ids[1:cardinality(base.traversal_ids)]`), which Arel
        #   has no built-in node for, so it is injected as a raw SQL
        #   fragment via `Arel.sql`.
        # - The base namespaces (those in the receiver relation) are joined
        #   via an aliased `base_namespaces` table and matched with `EXISTS`
        #   to avoid returning duplicate rows when multiple base namespaces
        #   share descendants.
        #
        # Returns an ActiveRecord::Relation of Namespace records (self + descendants).
        #
        # Note: see the comment on `#self_and_ancestors` - this is scoped to
        # `unscoped`, preserving the receiver's STI `type` condition. Use
        # `self_and_descendants_across_types` to query across STI types.
        def self_and_descendants
          unscoped.where(Arel::Nodes::Exists.new(descendant_match_subquery(select(:id).arel)))
        end

        def self_and_descendant_ids
          self_and_descendants.as_ids
        end

        # Same as `#self_and_descendants`, but queries `Namespace.unscoped`
        # instead of `unscoped`, so results are not restricted to the
        # receiver's STI type. Used internally by the instance-level
        # `#self_and_descendants_of_type` to find descendants of a different
        # STI type than the receiver (e.g. a Group's Project descendants).
        def self_and_descendants_across_types
          Namespace.unscoped.where(Arel::Nodes::Exists.new(descendant_match_subquery(select(:id).arel)))
        end

        # Return namespaces in the receiver relation that are not
        # descendants of any other namespace within the same relation. This
        # is useful when you want to filter a set of namespaces down to only
        # the top-level ones (no child namespaces included).
        #
        # Implementation:
        # - For each namespace in the relation, check whether another
        #   (different) namespace in the same relation is one of its
        #   ancestors (i.e. its `traversal_ids`, truncated to that other
        #   namespace's depth, equals the other namespace's `traversal_ids`).
        #   Namespaces for which such a match exists are excluded.
        #
        # Returns an ActiveRecord::Relation of Namespace records that have no
        # ancestors within the given relation.
        def without_descendants
          where.not(Arel::Nodes::Exists.new(ancestor_match_subquery(select(:id).arel)))
        end

        private

        def descendant_match_subquery(base_ids)
          base = Arel::Table.new(table_name, as: 'base_namespaces')
          slice = Arel.sql("#{table_name}.traversal_ids[1:cardinality(base_namespaces.traversal_ids)]")

          base.project(Arel.sql('1'))
              .where(base[:id].in(base_ids))
              .where(Arel::Nodes::Equality.new(slice, base[:traversal_ids]))
        end

        def ancestor_match_subquery(base_ids)
          other = Arel::Table.new(table_name, as: 'other_namespaces')
          slice = Arel.sql("#{table_name}.traversal_ids[1:cardinality(other_namespaces.traversal_ids)]")

          other.project(Arel.sql('1'))
               .where(other[:id].in(base_ids))
               .where(other[:id].not_eq(Namespace.arel_table[:id]))
               .where(Arel::Nodes::Equality.new(slice, other[:traversal_ids]))
        end
      end
    end
  end
end
