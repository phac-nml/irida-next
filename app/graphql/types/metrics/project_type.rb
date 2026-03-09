# frozen_string_literal: true

module Types
  module Metrics
    # Project Type
    class ProjectType < Types::BaseType
      implements GraphQL::Types::Relay::Node
      implements Types::NamespaceMetricsType

      graphql_name 'ProjectMetricsType'
      description 'Project to get metrics for'

      field :name, String, null: false, description: 'Name of the project.'
      field :puid, ID, null: false,
                       description: 'Persistent Unique Identifier of the project, in the format
                                  `INXT_PRJ_AAAAAAAAAA`.'

      field :parent, String, null: true, description: 'Parent namespace of this namespace'

      def self.authorized?(object, context)
        super && context[:current_user]&.system?
      end
    end
  end
end
