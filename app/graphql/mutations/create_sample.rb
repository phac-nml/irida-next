# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CreateSample < BaseMutation
    null true
    description 'Create a new sample within an existing project.'
    argument :description, String, required: false, description: 'The description to give the sample.'
    argument :name, String, required: true, description: 'The name to give the sample.'
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[project_id project_puid] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :sample, Types::SampleType, description: 'The newly created sample.'

    def resolve(args)
      project = get_project_from_id_or_puid_args(args)

      if project.nil? || !project.persisted?
        user_errors = [{
          path: ['project'],
          message: 'Project not found by provided ID or PUID'
        }]
        return {
          sample: nil,
          errors: user_errors
        }
      end

      create_sample(project, args)
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end

    private

    def create_sample(project, args) # rubocop:disable Metrics/MethodLength
      sample = Samples::CreateService.new(
        current_user, project, { name: args[:name], description: args[:description] }
      ).execute

      if sample.persisted?
        {
          sample:,
          errors: []
        }
      else
        user_errors = sample.errors.map do |error|
          {
            path: ['sample', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
        {
          sample: nil,
          errors: user_errors
        }
      end
    end
  end
end
