# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateSample < BaseMutation
    null true
    description 'Create a new sample within an existing project.'
    argument :description, String, description: 'The description to give the sample.'
    argument :name, String, required: true, description: 'The name to give the sample.'
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: true,
             description: 'The Node ID of the project to switch the sample will be created in.'

    field :errors, [String], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, description: 'The newly created sample.'

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

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
