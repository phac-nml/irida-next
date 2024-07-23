# frozen_string_literal: true

module Mutations
  # Mutation that updates sample metadata
  class UpdateSampleMetadata < BaseMutation
    description 'Update metadata for a sample.'
    argument :metadata, GraphQL::Types::JSON, required: true, description: 'The metadata to update the sample with.'
    argument :sample_id, ID,
             required: false,
             description: 'The Node ID of the sample to be updated. For example, `gid://irida/Sample/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :sample_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the sample. For example, `INXT_SAM_AAAAAAAAAA`.'
    validates required: { one_of: %i[sample_id sample_puid] }

    field :errors, [String], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, null: false, description: 'The updated sample.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      sample = if args[:sample_id]
                 IridaSchema.object_from_id(args[:sample_id], { expected_type: Sample })
               else
                 Sample.find_by(puid: args[:sample_puid])
               end
      if sample.nil?
        return {
          sample:,
          status: nil,
          errors: ['Sample not found by provided ID or PUID']
        }
      end

      metadata = args[:metadata]
      # convert string to hash if json string as given
      if metadata.is_a?(String)
        begin
          metadata = JSON.parse(metadata)
        rescue JSON::ParserError => e
          return {
            sample:,
            status: nil,
            error: "JSON data is not formatted correctly. #{e.message}"
          }
        end
      end

      unless metadata.is_a?(Hash)
        return {
          sample:,
          status: nil,
          errors: 'Metadata is not JSON data'
        }
      end

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
