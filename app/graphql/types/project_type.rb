# frozen_string_literal: true

module Types
  # Project Type
  class ProjectType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A project'

    field :description, String, null: true, description: 'Description of the project.'
    field :full_name, String, null: false, description: 'Full name of the project.'
    field :full_path, ID, null: false, description: 'Full path of the project.' # rubocop:disable GraphQL/ExtractType
    field :name, String, null: false, description: 'Name of the project.'
    field :path, String, null: false, description: 'Path of the project.'

    field :parent, NamespaceType, null: false, description: 'Parent namespace'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user] }
        )
    end
  end
end
