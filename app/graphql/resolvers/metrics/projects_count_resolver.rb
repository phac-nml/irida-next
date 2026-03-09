# frozen_string_literal: true

module Resolvers
  module Metrics
    # Namespace Project Count Resolver
    class ProjectsCountResolver < BaseResolver
      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to only include projects that directly belong to this namespace',
               default_value: false

      def resolve(direct_only:)
        return if object.is_a?(Project)

        if object.group_namespace?
          if direct_only
            object.project_namespaces.count
          else
            object.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
          end
        elsif object.user_namespace?
          object.project_namespaces.count
        end
      end
    end
  end
end
