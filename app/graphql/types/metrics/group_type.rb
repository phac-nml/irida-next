# frozen_string_literal: true

module Types
  module Metrics
    # Group Type
    class GroupType < Types::Metrics::NamespaceType
      implements GraphQL::Types::Relay::Node
      implements Types::NamespaceMetricType

      graphql_name 'GroupMetricsType'
      description 'Group to get metrics for'

      field :descendant_groups, Types::Metrics::GroupType.connection_type,
            null: true,
            description: 'Subgroups within this group namespace. This field is only applicable for group namespaces.',
            complexity: 5,
            resolver: Resolvers::Metrics::SubgroupsResolver

      def self.authorized?(object, context)
        super && context[:system_user]
      end
    end
  end
end
