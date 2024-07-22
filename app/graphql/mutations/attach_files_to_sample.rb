# frozen_string_literal: true

module Mutations
  # Mutation that attaches files to sample
  class AttachFilesToSample < BaseMutation
    description 'Attaches files to sample.'
    argument :files, [String], required: true, description: 'A list of files (signedBlobId) to attach to the sample'
    argument :sample_id, ID,
             required: false,
             description: 'The Node ID of the sample to be updated. For example, `gid://irida/Sample/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :sample_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the sample. For example, `INXT_SAM_AAAAAAAAAA`.'
    validates required: { one_of: %i[sample_id sample_puid] }

    field :errors, GraphQL::Types::JSON, null: false, description: 'Errors that prevented the mutation.'
    field :sample, Types::SampleType, null: true, description: 'The updated sample.'
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

      files_attached = Attachments::CreateService.new(current_user, sample, { files: args[:files] }).execute

      status, errors = attachment_status_and_errors(files_attached:, file_blob_id_list: args[:files])
      errors['query'] = sample.errors.full_messages if sample.errors.count.positive?

      {
        sample:,
        status:,
        errors:
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def attachment_status_and_errors(files_attached:, file_blob_id_list:)
      # initialize status hash such that all blob ids given by user are included
      status = Hash[*file_blob_id_list.collect { |v| [v, nil] }.flatten]
      errors = {}

      files_attached.each do |attachment|
        id = attachment.file.blob.signed_id
        if attachment.persisted?
          status[id] = :success
        else
          status[id] = :error
          errors[id] = attachment.errors.full_messages
        end
      end

      add_missing_blob_id_error(status:, errors:)
    end

    def add_missing_blob_id_error(status:, errors:)
      # any nil status is an error
      status.each do |id, value|
        if value.nil?
          status[id] = :error
          errors[id] = 'Blob id could not be processed. Blob id is invalid or file is missing.'
        end
      end

      [status, errors]
    end
  end
end
