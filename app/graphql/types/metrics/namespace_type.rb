# frozen_string_literal: true

module Types
  module Metrics
    # Namespace Type
    class NamespaceType < Types::BaseType
      implements GraphQL::Types::Relay::Node
      implements Types::NamespaceMetricType

      graphql_name 'NamespaceMetricsType'
      description 'Namespace for which to get project and/or groups for'

      field :name, String, null: false, description: 'Name of the namespace.'
      field :puid, ID, null: false,
                       description: 'Persistent Unique Identifier of the namespace. For example for a group,
                                  `INXT_GRP_AAAAAAAAAA`.'
      field :type, String, null: false, description: 'Type of the namespace'

      field :parent, String, null: true, description: 'Parent namespace of this namespace'

      field :projects, Types::Metrics::ProjectType.connection_type,
            null: true,
            description: 'Projects within this namespace',
            complexity: 5,
            resolver: Resolvers::Metrics::ProjectsResolver

      field :projects_count, Integer, null: true,
                                      description: 'Total number of projects under the namespace.',
                                      resolver: Resolvers::Metrics::ProjectsCountResolver

      def self.authorized?(object, context)
        super && context[:current_user]&.system?
      end

      def self.visible?(context)
        super && context[:current_user]&.system?
      end
    end
  end
end
