# frozen_string_literal: true

module Types
  # Project Type
  class MetricProjectType < MetricNamespaceType
    implements GraphQL::Types::Relay::Node
    description 'A project'

    field :metrics, Types::MetricType,
          null: true,
          description: 'Metrics for the project',
          resolver: Resolvers::MetricsResolver

    def self.authorized?(object, context)
      super && context[:system_user]
    end
  end
end
