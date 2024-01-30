# frozen_string_literal: true

module Mutations
  # Mutation that attaches files to sample
  class AttachFilesToSample < BaseMutation
    description 'Attaches files to sample.'
    argument :files, [String], required: true, description: 'A list of files (signedBlobId) to attach to the sample'
    argument :sample_id, ID,
             required: true,
             description: 'The Node ID of the sample to be updated.'

    field :errors, [String], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, null: false, description: 'The updated sample.'
    field :status, GraphQL::Types::JSON, null: false, description: 'The status of the mutation.'

    def resolve(sample_id:, files:)
      sample = IridaSchema.object_from_id(sample_id, { expected_type: Sample })
      files_attached = Attachments::CreateService.new(current_user, sample, { 'files' => files }).execute
      {
        sample:,
        status: files_attached,
        errors: sample.errors.full_messages
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
