# frozen_string_literal: true

module Types
  # Namespace Type
  class MetricNamespaceType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A namespace'

    field :name, String, null: false, description: 'Name of the namespace.'
    field :puid, ID, null: false,
                     description: 'Persistent Unique Identifier of the namespace. For example for a group,
                                  `INXT_GRP_AAAAAAAAAA`.'

    field :projects, Types::MetricProjectType.connection_type,
          null: true,
          description: 'Projects within this namespace',
          complexity: 5,
          resolver: Resolvers::MetricsProjectsResolver

    field :groups, Types::MetricGroupType.connection_type,
          null: true,
          description: 'Groups within this namespace',
          complexity: 5,
          resolver: Resolvers::MetricsGroupsResolver

    def self.authorized?(object, context)
      super && context[:system_user]
    end
  end
end
