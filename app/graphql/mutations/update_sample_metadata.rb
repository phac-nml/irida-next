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

    field :errors, [Types::UserErrorType], description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, null: true, description: 'The updated sample.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      sample = get_sample(args)

      if sample.nil?
        user_errors = [{
          path: ['sample'],
          message: 'not found by provided ID or PUID'
        }]
        return {
          sample:,
          status: nil,
          errors: user_errors
        }
      end

      metadata = args[:metadata]
      # convert string to hash if json string as given
      metadata = JSON.parse(metadata) if metadata.is_a?(String)

      unless metadata.is_a?(Hash)
        user_errors = [{
          path: ['metadata'],
          message: 'is not JSON data'
        }]
        return {
          sample:,
          status: nil,
          errors: user_errors
        }
      end

      metadata_changes = Samples::Metadata::UpdateService.new(sample.project, sample, current_user,
                                                              { 'metadata' => metadata }).execute

      user_errors = sample.errors.map do |error|
        {
          path: ['sample', error.attribute.to_s.camelize(:lower)],
          message: error.message
        }
      end
      {
        sample:,
        status: metadata_changes,
        errors: user_errors
      }
    rescue JSON::ParserError => e
      user_errors = [{
        path: ['metadata'],
        message: "JSON data is not formatted correctly. #{e.message}"
      }]
      {
        sample: nil,
        status: nil,
        errors: user_errors
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def get_sample(args)
      if args[:sample_id]
        IridaSchema.object_from_id(args[:sample_id], { expected_type: Sample })
      else
        Sample.find_by!(puid: args[:sample_puid])
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
