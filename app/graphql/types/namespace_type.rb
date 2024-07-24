# frozen_string_literal: true

module Types
  # Namespace Type
  class NamespaceType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A namespace'

    field :description, String, null: true, description: 'Description of the namespace.'
    field :full_name, String, null: false, description: 'Full name of the namespace.'
    field :full_path, ID, null: false, description: 'Full path of the namespace.' # rubocop:disable GraphQL/ExtractType
    field :name, String, null: false, description: 'Name of the namespace.'
    field :path, String, null: false, description: 'Path of the namespace.'
    field :puid, ID, null: false,
                     description: 'Persistent Unique Identifier of the namespace. For example for a group,
                                  `INXT_GRP_AAAAAAAAAA`.'

    field :projects, ProjectType.connection_type,
          null: true,
          description: 'Projects within this namespace',
          complexity: 5,
          resolver: Resolvers::NamespaceProjectsResolver

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
