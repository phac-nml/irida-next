# frozen_string_literal: true

module Resolvers
  module Metrics
    # Projects Resolver
    class ProjectsResolver < BaseResolver
      graphql_name 'MetricsProjectsResolver'
      type Types::Metrics::ProjectType, null: true

      alias namespace object

      argument :include_sub_groups, GraphQL::Types::Boolean,
               required: false,
               description: 'Include projects from subgroups.',
               default_value: false

      def resolve(args)
        scope = namespace

        scope = scope.self_and_descendants if namespace.group_namespace? && args[:include_sub_groups]

        Project.joins(:namespace).where(namespace: { parent: scope })
      end
    end
  end
end
