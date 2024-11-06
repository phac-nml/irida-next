# frozen_string_literal: true

module Mutations
  # Base Mutation
  class SubmitWorkflowExecution < BaseMutation
    null true
    description 'Create a new workflow execution..'

    argument :name, String
    argument :workflow_name, String
    argument :workflow_version, String
    argument :namespace_id, ID # TODO: replace with an either-or group or project, and extract namespace id from whichever is provided
    argument :workflow_params, GraphQL::Types::JSON
    argument :workflow_type, String
    argument :workflow_type_version, String
    argument :workflow_engine, String
    argument :workflow_engine_version, String
    argument :workflow_engine_parameters, [GraphQL::Types::JSON] # TODO: is there a better way to handle keys that start with "-"
    argument :workflow_url, String

    argument :update_samples, String # TODO: make this a bool and turn into "1" or "0"
    argument :email_notification, String # TODO: make this a bool and turn into "1" or "0"

    # argument :samples_workflow_executions_attributes, GraphQL::Types::JSON
    argument :sample_info_list, [GraphQL::Types::JSON] # TODO: give this a better name

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :workflow_execution, Types::WorkflowExecutionType, description: 'The newly created workflow execution.'

    def resolve(args)
      create_workflow_execution(args)
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
    end

    private

    def create_workflow_execution(args) # rubocop:disable Metrics/MethodLength
      workflow_execution_params = {
        name: args[:name],
        metadata: { workflow_name: args[:workflow_name],
                    workflow_version: args[:workflow_version] },
        namespace_id: args[:namespace_id],
        workflow_params: args[:workflow_params],
        workflow_type: args[:workflow_type],
        workflow_type_version: args[:workflow_type_version],
        workflow_engine: args[:workflow_engine],
        workflow_engine_version: args[:workflow_engine_version],
        # TODO: fix this issue with key starting with "-r"
        # workflow_engine_parameters: args[:workflow_engine_parameters],
        workflow_engine_parameters: workflow_engine_parameters(args[:workflow_engine_parameters]),
        workflow_url: args[:workflow_url],
        update_samples: args[:update_samples],
        email_notification: args[:email_notification],
        samples_workflow_executions_attributes: samples_workflow_executions_attributes(args[:sample_info_list])
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
        # TODO
        # user_errors = project.errors.map do |error|
        #   {
        #     path: ['workflow_execution', error.attribute.to_s.camelize(:lower)],
        #     message: error.message
        #   }
        # end
        {
          workflow_execution: nil,
          # errors: user_errors
          errors: nil
        }
      end
    end

    def workflow_engine_parameters(parameter_list)
      result = {}
      parameter_list.each do |params|
        result[params['key']] = params['value']
      end
      result
    end

    def samples_workflow_executions_attributes(sample_info_list)
      result = {}
      sample_info_list.each_with_index do |sample_info, index|
        key = index.to_s
        # TODO: endable this error handling for sample_id's
        # begin
          sample = IridaSchema.object_from_id(sample_info['sample_id'], { expected_type: Sample })
        # rescue GraphQL::CoercionError => e
        #   user_errors.append(
        #     {
        #       path: ['copySamples'],
        #       message: e.message
        #     }
        #   )
        #   next
        # end

        samplesheet_params = { 'sample' => sample.puid }
        sample_info['files'].each do |file_info|
          # TODO: file id error checking should probably be done as a validate step on the WorkflowExecution object
          samplesheet_params[file_info['file_type']] = file_info['file_id']
        end

        result[key] = {
          'sample_id' => sample.id,
          'samplesheet_params' => samplesheet_params
        }
      end

      result
    end
  end
end
