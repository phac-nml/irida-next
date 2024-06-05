# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateSample < BaseMutation
    null true
    description 'Create a new sample within an existing project.'
    argument :description, String, description: 'The description to give the sample.'
    argument :name, String, required: true, description: 'The name to give the sample.'
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[project_id project_puid] }

    field :errors, [String], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, description: 'The newly created sample.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      project = if args[:project_id]
                  IridaSchema.object_from_id(args[:project_id], { expected_type: Project })
                else
                  Namespaces::ProjectNamespace.find_by!(puid: args[:project_puid]).project
                end
      sample = Samples::CreateService.new(current_user, project,
                                          { name: args[:name], description: args[:description] }).execute
      if sample.persisted?
        {
          sample:,
          errors: []
        }
      else
        {
          sample: nil,
          errors: sample.errors.full_messages
        }
      end
    rescue ActiveRecord::RecordNotFound
      {
        sample: nil,
        errors: ['Project not found by provided ID or PUID']
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end
  end
end
