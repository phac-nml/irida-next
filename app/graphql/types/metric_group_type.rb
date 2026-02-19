# frozen_string_literal: true

module Types
  # Group Type
  class MetricGroupType < MetricNamespaceType
    implements GraphQL::Types::Relay::Node
    description 'A group'

    field :metrics, Types::MetricType,
          null: true,
          description: 'Metrics for the group',
          resolver: Resolvers::MetricsResolver

    def self.authorized?(object, context)
      super && context[:system_user]
    end
  end
end
