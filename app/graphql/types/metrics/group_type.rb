# frozen_string_literal: true

module Types
  module Metrics
    # Group Type
    class GroupType < NamespaceType
      implements GraphQL::Types::Relay::Node
      graphql_name 'GroupMetricsType'
      description 'A group'

      field :metrics, Types::Metrics::MetricType,
            null: true,
            description: 'Metrics for the group',
            resolver: Resolvers::Metrics::ObjectResolver

      def self.authorized?(object, context)
        super && context[:system_user]
      end
    end
  end
end
