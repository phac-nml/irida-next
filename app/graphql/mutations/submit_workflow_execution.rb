# frozen_string_literal: true

module Mutations
  # Base Mutation
  class SubmitWorkflowExecution < BaseMutation # rubocop:disable Metrics/ClassLength
    null true
    description 'Create a new workflow execution..'

    argument :email_notification, Boolean,
             description: 'Set to true to enable email notifications from this workflow execution'
    argument :name, String, description: 'Name for the new workflow.'
    argument :samples_files_info_list, [GraphQL::Types::JSON], description: 'List of hashes containing a `sample_id` (String), and `files` (Hash) containing pairs of `file_type` (String) (e.g. `fastq_1`) and `file_id` (String) (e.g. `gid://irida/Attachment/1234`).' # rubocop:disable GraphQL/ExtractInputType,Layout/LineLength
    argument :update_samples, Boolean, description: 'Set true for samples to be updated from this workflow execution' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_engine, String, description: '' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_engine_parameters, [GraphQL::Types::JSON], description: 'List of Hashes containing `key` and `value` to be passed to the workflow engine.' # rubocop:disable GraphQL/ExtractInputType,Layout/LineLength
    argument :workflow_engine_version, String, description: 'Workflow Engine Version' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_name, String, description: 'Name of the pipeline to be run on this workflow execution' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_params, GraphQL::Types::JSON, description: 'Parameters to be passed to the pipeline.' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_type, String, description: 'Type of pipelines workflow.' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_type_version, String, description: 'Version of the pipelines workflow type.' # rubocop:disable GraphQL/ExtractInputType
    argument :workflow_url, String, description: 'Url for the pipeline.' # rubocop:disable GraphQL/ExtractInputType
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
    end

    private

    def create_workflow_execution(args) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      workflow_engine_parameters = build_workflow_engine_parameters(args[:workflow_engine_parameters])

      update_samples = args[:update_samples] ? '1' : '0'
      email_notification = args[:email_notification] ? '1' : '0'

      namespace_id = namespace(args[:project_id], args[:group_id])

      samples_workflow_executions_attributes = build_samples_workflow_executions_attributes(args[:samples_files_info_list]) # rubocop:disable Layout/LineLength

      workflow_execution_params = {
        name: args[:name],
        metadata: { workflow_name: args[:workflow_name],
                    workflow_version: args[:workflow_version] },
        namespace_id:,
        workflow_params: args[:workflow_params],
        workflow_type: args[:workflow_type],
        workflow_type_version: args[:workflow_type_version],
        workflow_engine: args[:workflow_engine],
        workflow_engine_version: args[:workflow_engine_version],
        workflow_engine_parameters:,
        workflow_url: args[:workflow_url],
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

    # workflow engine parameters can have keys that start with `-` which is not allowed in graphql,
    # so we parse a list of key value pairs into a hash that can be used.
    def build_workflow_engine_parameters(parameter_list)
      result = {}
      parameter_list.each do |params|
        result[params['key']] = params['value']
      end
      result
    end

    def build_samples_workflow_executions_attributes(sample_info_list)
      result = {}
      sample_info_list.each_with_index do |sample_info, index|
        sample = IridaSchema.object_from_id(sample_info['sample_id'], { expected_type: Sample })

        # pass samplesheet params as a flat json structure
        #
        # samplesheet_params = { 'sample' => sample.puid }
        # sample_info['files'].each do |file_info|
        #   samplesheet_params[file_info['file_type']] = file_info['file_id']
        # end

        # We expect results to have numbered entries as strings starting with "0", so we use the index
        result[index.to_s] = {
          'sample_id' => sample.id,
          'samplesheet_params' => samplesheet_params
        }
      end

      result
    end
  end
end
