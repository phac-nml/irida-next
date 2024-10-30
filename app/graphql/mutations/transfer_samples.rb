# frozen_string_literal: true

module Mutations
  # Base Mutation
  class TransferSamples < BaseMutation
    null true
    description 'Transfer a list of sample to another project.'
    argument :new_project_id, ID,
             required: false,
             description: 'The Node ID of the project to transfer to. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :new_project_puid, ID,
             required: false,
             description: 'Persistent Unique Identifier of the project to transfer to. For example, `INXT_PRJ_AAAAAAAAAA`.' # rubocop:disable Layout/LineLength
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project to transfer to. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project to transfer to. For example, `INXT_PRJ_AAAAAAAAAA`.' # rubocop:disable Layout/LineLength

    argument :sample_ids, [ID], required: true, description: 'List of samples to transfer.' # rubocop:disable GraphQL/ExtractInputType
    validates required: { one_of: %i[new_project_id new_project_puid] }
    validates required: { one_of: %i[project_id project_puid] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :samples, [ID], description: 'List of transfered sample ids.'

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

      transfer_samples(project, new_project.id, args[:sample_ids])
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def transfer_samples(project, new_project_id, sample_gids) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      user_errors = []
      # remove prefix from sample_ids
      sample_ids = sample_gids.map do |sample_gid|
        IridaSchema.parse_gid(sample_gid, { expected_type: Sample }).model_id
      rescue GraphQL::CoercionError => e
        user_errors.append(
          {
            path: ['transferSamples'],
            message: e.message
          }
        )
        next
      end

      samples = Samples::TransferService.new(
        project, current_user
      ).execute(new_project_id, sample_ids.compact)

      if samples.empty? # rubocop:disable Style/ConditionalAssignment
        samples = nil
      else
        # add the prefix to sample_ids
        samples = samples.map do |sample_id|
          URI::GID.build(app: GlobalID.app, model_name: Sample.name, model_id: sample_id).to_s
        end
      end

      project_user_errors = []
      if project.errors.count.positive?
        project_user_errors = project.errors.map do |error|
          {
            path: ['samples', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end

      {
        samples:,
        errors: user_errors.concat(project_user_errors)
      }
    end
  end
end
