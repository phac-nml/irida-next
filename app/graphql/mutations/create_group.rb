# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateGroup < BaseMutation
    null true
    description 'Create a new group..'
    argument :description, String, required: false, description: 'The description to give the group.'
    argument :group_id, ID,
             required: false,
             description: 'The Node ID of a group to create the sub group in. For example, `gid://irida/Group/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :group_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of a group to create the sub group in. For example, `INXT_GRP_AAAAAAAAAA`.' # rubocop:disable Layout/LineLength
    argument :name, String, required: true, description: 'The name to give the group.' # rubocop:disable GraphQL/ExtractInputType
    argument :path, String, required: false, description: 'A custom path for the group.' # rubocop:disable GraphQL/ExtractInputType

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :group, Types::GroupType, description: 'The newly created group.'

    def resolve(args)
      parent_group = nil

      if args[:group_id] || args[:group_puid]
        parent_group = get_group_from_id_or_puid_args(args)

        if parent_group.nil? || !parent_group.persisted?
          user_errors = [{ path: ['group'], message: 'Group not found by provided ID or PUID' }]
          return { group: nil, errors: user_errors }
        end
      end

      # slugify path, if no path given slugify name to use as path
      args[:path] = if args[:path]
                      args[:path].to_s.parameterize(separator: '-')
                    else
                      args[:name].to_s.parameterize(separator: '-')
                    end
      create_group(args, parent_group)
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def create_group(args, parent_group = nil) # rubocop:disable Metrics/MethodLength
      params = {
        name: args[:name],
        path: args[:path],
        description: args[:description]
      }

      params[:parent_id] = parent_group.id if parent_group

      group = Groups::CreateService.new(current_user, params).execute

      if group.persisted?
        {
          group:,
          errors: []
        }
      else
        user_errors = group.errors.map do |error|
          {
            path: ['group', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
        {
          group: nil,
          errors: user_errors
        }
      end
    end
  end
end
