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

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, null: true, description: 'The updated sample.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      sample = get_sample_from_id_or_puid_args(args)

      if sample.nil?
        return {
          sample:,
          status: nil,
          errors: [{ path: ['sample'], message: 'not found by provided ID or PUID' }]
        }
      end

      files_attached = Attachments::CreateService.new(current_user, sample, { files: args[:files] }).execute

      status, user_errors = attachment_status_and_errors(files_attached:, file_blob_id_list: args[:files])

      # append query level errors
      user_errors.push(*get_errors_from_object(sample, 'sample'))

      {
        sample:,
        status:,
        errors: user_errors
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
