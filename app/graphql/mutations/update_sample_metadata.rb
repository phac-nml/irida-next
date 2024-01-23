# frozen_string_literal: true

module Mutations
  # Mutation that updates sample metadata
  class UpdateSampleMetadata < BaseMutation
    description 'Update metadata for a sample.'
    argument :metadata, GraphQL::Types::JSON, required: true, description: 'The metadata to update the sample with.'
    argument :sample_id, ID,
             required: true,
             description: 'The Node ID of the sample to be updated.'

    field :errors, [String], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, null: false, description: 'The updated sample.'
    field :status, GraphQL::Types::JSON, null: false, description: 'The status of the mutation.'

    def resolve(sample_id:, metadata:)
      sample = IridaSchema.object_from_id(sample_id, { expected_type: Sample })
      metadata_changes = Samples::Metadata::UpdateService.new(sample.project, sample, current_user,
                                                              { 'metadata' => metadata }).execute

      {
        sample:,
        status: metadata_changes,
        errors: sample.errors.full_messages
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
