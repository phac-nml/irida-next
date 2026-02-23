# frozen_string_literal: true

module Types
  module Metrics
    # Namespace Type
    class NamespaceType < Types::BaseType
      implements GraphQL::Types::Relay::Node
      graphql_name 'NamespaceMetricsType'
      description 'A namespace'

      field :name, String, null: false, description: 'Name of the namespace.'
      field :puid, ID, null: false,
                       description: 'Persistent Unique Identifier of the namespace. For example for a group,
                                  `INXT_GRP_AAAAAAAAAA`.'
      field :type, String, null: false, description: 'Type of the namespace'

      field :metrics, Types::Metrics::MetricType, null: true, description: 'Metrics for all projects under namespace',
                                                  resolver: Resolvers::Metrics::ObjectResolver

      field :projects, Types::Metrics::ProjectType.connection_type,
            null: true,
            description: 'Projects within this namespace',
            complexity: 5,
            resolver: Resolvers::Metrics::ProjectsResolver

      field :groups, Types::Metrics::GroupType.connection_type,
            null: true,
            description: 'Groups within this namespace',
            complexity: 5,
            resolver: Resolvers::Metrics::SubgroupsResolver

      def self.authorized?(object, context)
        super && context[:system_user]
      end
    end
  end
end
