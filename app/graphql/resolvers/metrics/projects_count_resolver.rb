# frozen_string_literal: true

module Resolvers
  module Metrics
    # Namespace Project Count Resolver
    class ProjectsCountResolver < BaseResolver
      def resolve
        return if object.is_a?(Project)

        if object.group_namespace?
          if context[:direct_only]
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
