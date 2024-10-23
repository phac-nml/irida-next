# frozen_string_literal: true

module Mutations
  # Base Mutation
  class CloneSamples < BaseMutation
    null true
    description 'Copy samples to another project.'
    argument :new_project_id, ID,
             required: false,
             description: 'The Node ID of the project to copy to. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :new_project_puid, ID,
             required: false,
             description: 'Persistent Unique Identifier of the project to copy to. For example, `INXT_PRJ_AAAAAAAAAA`.'
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project to copy to. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project to copy to. For example, `INXT_PRJ_AAAAAAAAAA`.'

    argument :sample_ids, [ID], required: true, description: 'List of samples to copy.' # rubocop:disable GraphQL/ExtractInputType
    validates required: { one_of: %i[new_project_id new_project_puid] }
    validates required: { one_of: %i[project_id project_puid] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :samples, GraphQL::Types::JSON, description: 'List of original and copied sample ids.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      project = get_project_from_id_or_puid_args(args)

      if project.nil? || !project.persisted?
        user_errors = [{
          path: ['project'],
          message: 'Project not found by provided ID or PUID'
        }]
        return {
          samples: nil,
          errors: user_errors
        }
      end

      new_project_args = { project_id: args[:new_project_id], project_puid: args[:new_project_puid] }
      new_project = get_project_from_id_or_puid_args(new_project_args)

      if new_project.nil? || !new_project.persisted?
        user_errors = [{
          path: ['new_project'],
          message: 'Project not found by provided ID or PUID'
        }]
        return {
          samples: nil,
          errors: user_errors
        }
      end

      clone_samples(project, new_project.id, args[:sample_ids])
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def clone_samples(project, new_project_id, sample_ids) # rubocop:disable Metrics/MethodLength
      # remove prefix from sample_ids
      sample_ids.each { |sample_id| sample_id.sub!(SAMPLE_ID_PREFIX, '') }

      samples = Samples::CloneService.new(
        project, current_user
      ).execute(new_project_id, sample_ids)

      prepended_samples = nil
      unless samples.empty?
        # add the prefix to sample_ids
        prepended_samples = samples.map do |key, value|
          { original: "#{SAMPLE_ID_PREFIX}#{key}",
            copy: "#{SAMPLE_ID_PREFIX}#{value}" }
        end
      end

      user_errors = []
      if project.errors.count.positive?
        user_errors = project.errors.map do |error|
          {
            path: ['samples', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end

      {
        samples: prepended_samples,
        errors: user_errors
      }
    end
  end
end
