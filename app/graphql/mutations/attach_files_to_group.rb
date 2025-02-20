# frozen_string_literal: true

module Mutations
  # Mutation that attaches files to group
  class AttachFilesToGroup < BaseMutation
    description 'Attaches files to group.'
    argument :files, [String], required: true, description: 'A list of files (signedBlobId) to attach to the group'
    argument :group_id, ID,
             required: false,
             description: 'The Node ID of the group to be updated. For example, `gid://irida/group/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :group_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the group. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[group_id group_puid] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :group, Types::GroupType, null: true, description: 'The updated group.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      group = get_group_from_id_or_puid_args(args)

      if group.nil?
        return {
          group:,
          status: nil,
          errors: [{ path: ['group'], message: 'not found by provided ID or PUID' }]
        }
      end

      files_attached = Attachments::CreateService.new(current_user, group, { files: args[:files] }).execute

      status, user_errors = attachment_status_and_errors(files_attached:, file_blob_id_list: args[:files])

      # append query level errors
      user_errors.push(*get_errors_from_object(group, 'group'))

      {
        group:,
        status:,
        errors: user_errors
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end
  end
end
