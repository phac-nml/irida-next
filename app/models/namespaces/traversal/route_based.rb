# frozen_string_literal: true

module Namespaces
  module Traversal
    # Provides route-based traversal helpers for namespace hierarchies.
    module RouteBased
      extend ActiveSupport::Concern
      include RouteBasedScopes

      def ancestors
        return self.class.none if parent_id.blank?

        self_and_ancestors.where.not(id:)
      end
      alias route_based_ancestors ancestors

      def ancestor_ids
        ancestors.as_ids
      end
      alias route_based_ancestor_ids ancestor_ids

      def self_and_ancestors
        return self.class.where(id:) if parent_id.blank?

        self_and_ancestors_of_type(self.class.sti_name)
      end
      alias route_based_self_and_ancestors self_and_ancestors

      # Return namespaces whose routes are ancestors of the current namespace
      # (filtered by the provided STI `types`). This variant accepts an explicit
      # set of types and is used by `self_and_ancestors` to restrict results to
      # particular namespace subtypes (e.g. Group, ProjectNamespace).
      #
      # Implementation details:
      # - Projects a CONCAT(path, '/') expression from the `routes` table for the
      #   current set of routes and matches it against routes whose path begins
      #   with that projected value using a trailing wildcard (CONCAT(path, '/%')).
      # - Uses Arel functions to build the CONCAT and LIKE expressions because
      #   the SQL is Postgres-specific and not modelled directly by Arel.
      # - We call the helpers on `self.class` because `concat_path_with_slash` and
      #   `concat_path_with_wildcard` are defined as class-level helpers inside the
      #   `class << self` block above. Calling them via `self.class` keeps this
      #   instance-level method concise while reusing the shared Arel builders.
      #
      # @param types [Array<String>, String] STI type(s) to filter the namespaces
      # @return [ActiveRecord::Relation<Namespace>] matching ancestor namespaces of the given types
      def self_and_ancestors_of_type(types)
        Namespace.joins(:route)
                 .where(
                   Arel::Nodes::Grouping.new(
                     Route.arel_table.project(
                       self.class.concat_path_with_slash(Route.arel_table[:path])
                     ).where(Route.arel_table[:source_id].eq(id))
                   ).matches(self.class.concat_path_with_wildcard(Route.arel_table[:path]))
                 ).where(type: types)
      end
      alias route_based_self_and_ancestors_of_type self_and_ancestors_of_type

      def self_and_ancestor_ids
        self_and_ancestors.as_ids
      end
      alias route_based_self_and_ancestor_ids self_and_ancestor_ids

      def descendants
        self_and_descendants.where.not(id:)
      end
      alias route_based_descendants descendants

      def self_and_descendants
        self_and_descendants_of_type(self.class.sti_name)
      end
      alias route_based_self_and_descendants self_and_descendants

      # Return namespaces whose routes are descendants of the current namespace
      # (filtered by the provided STI `types`). This variant accepts an explicit
      # set of types and is used by `self_and_descendants` to restrict results to
      # particular namespace subtypes (e.g. Group, ProjectNamespace).
      #
      # Implementation details:
      # - Matches routes whose `path` begins with the current namespace's
      #   `full_path` (or `full_path/` followed by anything) using SQL `LIKE` with
      #   a trailing '/%' wildcard. We use Arel's `matches_any` for the OR-style
      #   pattern matching against both exact path and prefixed descendants.
      # - This method keeps the Arel expression straightforward by delegating
      #   the path concatenation and wildcard creation to the class-level helpers
      #   where appropriate; here we inline a `matches_any` over the two patterns
      #   since the descendants check is simple and avoids extra subqueries.
      #
      # @param types [Array<String>, String] STI type(s) to filter the namespaces
      # @return [ActiveRecord::Relation<Namespace>] matching descendant namespaces of the given types
      def self_and_descendants_of_type(types)
        route_path = Route.arel_table[:path]

        Namespace.joins(:route)
                 .where(route_path.matches_any([full_path, "#{full_path}/%"]))
                 .where(type: types)
      end

      def self_and_descendant_ids
        self_and_descendants.as_ids
      end
      alias route_based_self_and_descendant_ids self_and_descendant_ids
    end
  end
end
