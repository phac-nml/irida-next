# frozen_string_literal: true

module Types
  module Metrics
    # Project Type
    class ProjectType < NamespaceType
      implements GraphQL::Types::Relay::Node
      graphql_name 'ProjectMetricsType'
      description 'Project to get metrics for'

      field :metrics, Types::Metrics::MetricType,
            null: true,
            description: 'Metrics for the project',
            resolver: Resolvers::Metrics::ObjectResolver

      def self.authorized?(object, context)
        super && context[:system_user]
      end
    end
  end
end
