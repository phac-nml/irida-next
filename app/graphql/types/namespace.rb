# frozen_string_literal: true

module Types
  # Namespace interface
  module Namespace
    include Types::BaseInterface
    # Add the `id` field
    include GraphQL::Types::Relay::NodeBehaviors
    description 'A namespace'

    field :description, String, null: false, description: 'Description of the namespace.'
    field :full_name, String, null: false, description: 'Full name of the namespace.'
    field :full_path, ID, null: false, description: 'Full path of the namespace.'
    field :name, String, null: false, description: 'Name of the namespace.'
    field :path, String, null: false, description: 'Path of the namespace.'
  end
end
