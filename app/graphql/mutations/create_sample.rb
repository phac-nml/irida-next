# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateSample < BaseMutation
    null true
    argument :description, String
    argument :name, String
    argument :project_id, ID

    field :errors, [String], null: false
    field :sample, Types::SampleType

    def resolve(name:, description:, project_id:)
      project = IridaSchema.object_from_id(project_id, { expected_type: Project })
      sample = Samples::CreateService.new(current_user, project, { name:, description: }).execute
      if sample.persisted?
        {
          sample:,
          errors: []
        }
      else
        {
          comment: nil,
          errors: sample.errors.full_messages
        }
      end
    end
  end
end
