# frozen_string_literal: true

module Namespaces
  module Traversal
    # Scopes for traversing namespace hierarchies using the `traversal_ids`
    # column (an array of the root-to-self chain of namespace ids) instead of
    # joining through the `routes` table.
    #
    # Every scope here is defined under its `linear_`-prefixed name, with the
    # unprefixed name as a plain alias. See the comment on
    # `Namespaces::Traversal::Linear` for why: when both this module and
    # `RouteBasedScopes` are mixed into `Namespace`, the last-included
    # module's bare (unprefixed) method names win, so any internal cross-call
    # here must use the `linear_`-prefixed name to avoid silently dispatching
    # to `RouteBasedScopes`' implementation instead of this one.
    module LinearScopes
      extend ActiveSupport::Concern

      class_methods do # rubocop:disable Metrics/BlockLength
        def linear_as_ids
          select(Namespace.arel_table[:id])
        end
        alias_method :as_ids, :linear_as_ids

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
        # Note: results are loaded from `Namespace.unscoped`, not
        # `unscoped` (i.e. `self.class.unscoped`). Ancestors of a namespace
        # are frequently a different STI subtype than the namespace itself
        # (e.g. a Project's ancestors are Groups) and Rails always applies
        # the receiver's STI `type` condition to a query, even past
        # `unscoped`, so querying through the subtype would silently drop
        # ancestors/descendants of other types.
        def linear_self_and_ancestors
          Namespace.unscoped.where(id: select(Arel.sql('unnest(namespaces.traversal_ids)')))
        end
        alias_method :self_and_ancestors, :linear_self_and_ancestors

        def linear_self_and_ancestor_ids
          linear_self_and_ancestors.linear_as_ids
        end
        alias_method :self_and_ancestor_ids, :linear_self_and_ancestor_ids

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
        # Note: see the comment on `#linear_self_and_ancestors` - this queries
        # `Namespace.unscoped` rather than `unscoped` for the same reason
        # (descendants may be a different STI subtype than the receiver).
        def linear_self_and_descendants
          Namespace.unscoped.where(Arel::Nodes::Exists.new(descendant_match_subquery(select(:id).arel)))
        end
        alias_method :self_and_descendants, :linear_self_and_descendants

        def linear_self_and_descendant_ids
          linear_self_and_descendants.linear_as_ids
        end
        alias_method :self_and_descendant_ids, :linear_self_and_descendant_ids

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
        def linear_without_descendants
          where.not(Arel::Nodes::Exists.new(ancestor_match_subquery(select(:id).arel)))
        end
        alias_method :without_descendants, :linear_without_descendants

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
