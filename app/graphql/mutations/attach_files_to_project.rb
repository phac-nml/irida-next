# frozen_string_literal: true

module Mutations
  # Mutation that attaches files to project
  class AttachFilesToProject < BaseMutation
    description 'Attaches files to project.'
    argument :files, [String], required: true, description: 'A list of files (signedBlobId) to attach to the project'
    argument :project_id, ID,
             required: false,
             description: 'The Node ID of the project to be updated. For example, `gid://irida/project/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[project_id project_puid] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :project, Types::ProjectType, null: true, description: 'The updated project.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      project = get_project_from_id_or_puid_args(args)

      if project.nil?
        return {
          project:,
          status: nil,
          errors: [{ path: ['project'], message: 'not found by provided ID or PUID' }]
        }
      end

      files_attached = Attachments::CreateService.new(current_user, project.namespace, { files: args[:files] }).execute

      status, user_errors = attachment_status_and_errors(files_attached:, file_blob_id_list: args[:files])

      # append query level errors
      user_errors.push(*get_errors_from_object(project.namespace, 'project'))

      {
        project:,
        status:,
        errors: user_errors
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
