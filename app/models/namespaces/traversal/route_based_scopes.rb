# frozen_string_literal: true

module Namespaces
  module Traversal
    # Scopes for traversing namespace routes and resolving ancestor/descendant
    # namespace collections via route path relationships.
    module RouteBasedScopes
      extend ActiveSupport::Concern

      class_methods do # rubocop:disable Metrics/BlockLength
        def as_ids
          select(Namespace.arel_table[:id])
        end

        # Return a relation containing this namespace (or namespaces from the
        # receiver relation) and all ancestor namespaces.
        #
        # Implementation:
        # - Builds an Arel subquery that finds route ids for any route that is an
        #   ancestor of the current namespace by matching path prefixes. The
        #   subquery uses a joined (aliased) `ancestral_routes` table and matches
        #   either the same id or a path prefix using `CONCAT(path, '/') LIKE
        #   CONCAT(ancestral_routes.path, '/%')`.
        # - Filters to routes whose `source_type` is the Namespace STI class and
        #   whose `source_id` is within the set of namespaces in the original
        #   relation (`select(:id).arel`). The result is a distinct list of route
        #   ids which is then used to find matching Namespace records via a
        #   join on `:route`.
        #
        # Returns an ActiveRecord::Relation of Namespace records (self + ancestors).
        def self_and_ancestors # rubocop:disable Metrics/AbcSize
          # build sql expression to select the route ids of the self and ancestral groups
          ancestral_routes = Arel::Table.new(Route.table_name, as: 'ancestral_routes')
          ancestral_route_ids = Route.arel_table.join(ancestral_routes, Arel::Nodes::OuterJoin).on(
            ancestral_routes[:id].eq(Route.arel_table[:id]).or(
              concat_path_with_slash(Route.arel_table[:path]).matches(
                concat_path_with_wildcard(ancestral_routes[:path])
              )
            )
          ).where(
            Route.arel_table[:source_type].eq(Namespace.sti_name).and(
              Route.arel_table[:source_id].in(select(:id).arel)
            ).and(Route.arel_table[:deleted_at].eq(nil))
          ).project(Route.arel_table[:id]).distinct

          unscoped
            .joins(:route)
            .where(Route.arel_table[:id].in(ancestral_route_ids))
        end
        alias_method :route_based_self_and_ancestors, :self_and_ancestors

        def self_and_ancestor_ids
          self_and_ancestors.as_ids
        end
        alias_method :route_based_self_and_ancestor_ids, :self_and_ancestor_ids

        # Return a relation containing this namespace and all descendant
        # namespaces.
        #
        # Implementation:
        # - Similar approach to `self_and_ancestors` but matches descendant paths
        #   by checking whether the descendant route's path matches the current
        #   namespace's path with a trailing '/%'. Uses an aliased
        #   `descendant_routes` table and constructs a distinct list of matching
        #   route ids which is used to filter namespaces.
        #
        # Returns an ActiveRecord::Relation of Namespace records (self + descendants).
        def self_and_descendants # rubocop:disable Metrics/AbcSize
          # build sql expression to select the route ids of the self and descendant groups
          descendant_routes = Arel::Table.new(Route.table_name, as: 'descendant_routes')
          descendant_route_ids = Route.arel_table.join(descendant_routes, Arel::Nodes::OuterJoin).on(
            descendant_routes[:id].eq(Route.arel_table[:id]).or(
              descendant_routes[:path].matches(
                concat_path_with_wildcard(Route.arel_table[:path])
              )
            )
          ).where(
            Route.arel_table[:source_type].eq(Namespace.sti_name).and(
              Route.arel_table[:source_id].in(select(:id).arel)
            ).and(Route.arel_table[:deleted_at].eq(nil))
          ).project(descendant_routes[:id]).distinct

          unscoped
            .joins(:route)
            .where(Route.arel_table[:id].in(descendant_route_ids))
        end
        alias_method :route_based_self_and_descendants, :self_and_descendants

        def self_and_descendant_ids
          self_and_descendants.as_ids
        end
        alias_method :route_based_self_and_descendant_ids, :self_and_descendant_ids

        # Return namespaces that do not have descendants inside the provided
        # collection. This is useful when you want to filter a set of namespaces
        # to only the top-level ones (no child namespaces included).
        #
        # Implementation:
        # - Builds a subquery producing wildcard paths (CONCAT(path, '/%')) for
        #   each joined route and then filters namespaces whose path does not
        #   match ANY of those wildcard patterns using PostgreSQL's `NOT LIKE ALL`
        #   semantics (`does_not_match` wraps `NOT ILIKE`/`NOT LIKE` depending on
        #   adapter).
        #
        # Returns an ActiveRecord::Relation of Namespace records that have no
        # descendants within the given relation.
        def without_descendants
          wildcard_path_select =
            joins(:route)
            .select(concat_path_with_wildcard(Route.arel_table[:path])).arel

          joins(:route)
            .where(Route.arel_table[:path].does_not_match(
                     Arel::Nodes::NamedFunction.new('ALL',
                                                    [Arel::Nodes::NamedFunction.new(
                                                      'ARRAY', [wildcard_path_select]
                                                    )])
                   ))
        end
        alias_method :route_based_without_descendants, :without_descendants
      end
    end
  end
end
