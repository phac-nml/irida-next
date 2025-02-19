# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateProject < BaseMutation
    null true
    description 'Create a new project..'
    argument :description, String, required: false, description: 'The description to give the project.'
    argument :group_id, ID,
             required: false,
             description: 'The Node ID of a group to create the project in. For example, `gid://irida/Group/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :group_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of a group to create the project in. For example, `INXT_GRP_AAAAAAAAAA`.' # rubocop:disable Layout/LineLength
    argument :name, String, required: true, description: 'The name to give the project.' # rubocop:disable GraphQL/ExtractInputType
    argument :path, String, required: false, description: 'A custom path for the project.' # rubocop:disable GraphQL/ExtractInputType

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :project, Types::ProjectType, description: 'The newly created project.'

    def resolve(args)
      namespace = get_namespace(args)

      if namespace.nil? || !namespace.persisted?
        user_errors = [{ path: ['group'], message: 'Group not found by provided ID or PUID' }]
        return { project: nil, errors: user_errors }
      end

      # if no path given slugify name to use as path
      args[:path] = args[:name].to_s.parameterize(separator: '-') unless args[:path]

      create_project(namespace, args)
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end

    private

    def get_namespace(args)
      # Only search for a group if an id/puid was provided, otherwise use user namespace
      if args[:group_id] || args[:group_puid]
        get_group_from_id_or_puid_args(args)
      else
        current_user.namespace
      end
    end

    def create_project(namespace, args) # rubocop:disable Metrics/MethodLength
      namespace_attributes = {
        name: args[:name],
        path: args[:path],
        description: args[:description],
        parent_id: namespace.id
      }

      project = Projects::CreateService.new(
        current_user, { namespace_attributes: }
      ).execute

      if project.persisted?
        {
          project:,
          errors: []
        }
      else
        user_errors = project.errors.map do |error|
          {
            path: ['project', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
        {
          project: nil,
          errors: user_errors
        }
      end
    end
  end
end
