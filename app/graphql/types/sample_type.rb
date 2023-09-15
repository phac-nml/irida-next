# frozen_string_literal: true

module Types
  # Sample Type
  class SampleType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A sample'

    field :description, String, null: true, description: 'Description of the sample.'
    field :name, String, null: false, description: 'Name of the sample.'
    field :project, ProjectType, null: false, description: 'Project the sample is on.'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read_sample?,
          object.project,
          context: { user: context[:current_user] }
        )
    end
  end
end
