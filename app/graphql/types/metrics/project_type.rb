# frozen_string_literal: true

module Types
  module Metrics
    # Project Type
    class ProjectType < Types::BaseType
      implements GraphQL::Types::Relay::Node
      implements Types::NamespaceMetricsType

      graphql_name 'ProjectMetricsType'
      description 'Project to get metrics for'

      field :name, String, null: false, description: 'Name of the namespace.'
      field :puid, ID, null: false,
                       description: 'Persistent Unique Identifier of the namespace. For example for a group,
                                  `INXT_GRP_AAAAAAAAAA`.'
      field :type, String, null: false, description: 'Type of the namespace'

      field :parent, String, null: true, description: 'Parent namespace of this namespace'

      def self.authorized?(object, context)
        super && context[:system_user]
      end
    end
  end
end
