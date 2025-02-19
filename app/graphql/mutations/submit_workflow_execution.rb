# frozen_string_literal: true

module Mutations
  # Base Mutation
  class SubmitWorkflowExecution < BaseMutation
    null true
    description 'Create a new workflow execution..'

    argument :email_notification,
             Boolean,
             required: false,
             default_value: false,
             description: 'Set to true to enable email notifications from this workflow execution'
    argument :name, String, required: false, description: 'Name for the new workflow.'
    argument :samples_workflow_executions_attributes, [GraphQL::Types::JSON], description: "A list of hashes containing a 'sample_id', and a hash of `samplesheet_params`." # rubocop:disable GraphQL/ExtractInputType,Layout/LineLength
    argument :update_samples, # rubocop:disable GraphQL/ExtractInputType
             Boolean,
             required: false,
             default_value: false,
             description: 'Set true for samples to be updated from this workflow execution'
    argument :workflow_name, String, description: 'Name of the pipeline to be run on this workflow execution' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_params, GraphQL::Types::JSON, description: 'Parameters to be passed to the pipeline.' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_version, String, description: 'Version of the pipeline to be run on this workflow execution' # rubocop:disable GraphQL/ExtractInputType

    # one of project/group, to use as the namespace
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project to run workflow in. For example, `gid://irida/Project/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    argument :group_id, ID, # rubocop:disable GraphQL/OrderedArguments,GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the group to run workflow in. For example, `gid://irida/Group/a84cd757-dedb-4c64-8b01-097020163077`.' # rubocop:disable Layout/LineLength
    validates required: { one_of: %i[project_id group_id] }

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :workflow_execution, Types::WorkflowExecutionType, description: 'The newly created workflow execution.'

    def resolve(args)
      create_workflow_execution(args)
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end

    private

    def create_workflow_execution(args) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      update_samples = args[:update_samples] ? '1' : '0'
      email_notification = args[:email_notification] ? '1' : '0'

      namespace_id = namespace(args[:project_id], args[:group_id])

      samples_workflow_executions_attributes = build_samples_workflow_executions_attributes(args[:samples_workflow_executions_attributes]) # rubocop:disable Layout/LineLength

      workflow_execution_params = {
        name: args[:name],
        metadata: { workflow_name: args[:workflow_name],
                    workflow_version: args[:workflow_version] },
        namespace_id:,
        workflow_params: args[:workflow_params],
        update_samples:,
        email_notification:,
        samples_workflow_executions_attributes:
      }

      workflow_execution = WorkflowExecutions::CreateService.new(
        current_user, workflow_execution_params
      ).execute

      if workflow_execution.persisted?
        {
          workflow_execution:,
          errors: []
        }
      else
        user_errors = workflow_execution.errors.map do |error|
          {
            path: ['workflow_execution', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
        {
          workflow_execution: nil,
          errors: user_errors
        }
      end
    end

    def namespace(project_id, group_id)
      if project_id
        IridaSchema.object_from_id(project_id, { expected_type: Project }).namespace.id
      else # group_id
        IridaSchema.object_from_id(group_id, { expected_type: Group }).id
      end
    end

    def build_samples_workflow_executions_attributes(samples_workflow_executions_attributes)
      result = {}
      samples_workflow_executions_attributes.each_with_index do |data, index|
        sample_id = IridaSchema.object_from_id(data['sample_id'], { expected_type: Sample }).id
        result[index.to_s] = {
          'sample_id' => sample_id,
          'samplesheet_params' => data['samplesheet_params']
        }
      end

      result
    end
  end
end
