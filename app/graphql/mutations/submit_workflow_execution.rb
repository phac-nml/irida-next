# frozen_string_literal: true

module Mutations
  # Base Mutation
  class SubmitWorkflowExecution < BaseMutation
    null true
    description 'Create a new workflow execution..'

    argument :name, String
    argument :workflow_name, String
    argument :workflow_version, String
    argument :namespace_id, ID
    argument :workflow_params, GraphQL::Types::JSON
    argument :workflow_type, String
    argument :workflow_type_version, String
    argument :workflow_engine, String
    argument :workflow_engine_version, String
    argument :workflow_engine_parameters, GraphQL::Types::JSON
    argument :workflow_url, String

    argument :update_samples, String
    argument :email_notification, String

    argument :samples_workflow_executions_attributes, GraphQL::Types::JSON

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
        metadata: { workflow_name: args[:workflow_name],
                    workflow_version: args[:workflow_version] },
        namespace_id: args[:namespace_id],
        workflow_params: args[:workflow_params],
        workflow_type: args[:workflow_type],
        workflow_type_version: args[:workflow_type_version],
        workflow_engine: args[:workflow_engine],
        workflow_engine_version: args[:workflow_engine_version],
        # TODO: fix this
        # workflow_engine_parameters: args[:workflow_engine_parameters],
        workflow_engine_parameters: { '-r' => '1.0.3' },
        workflow_url: args[:workflow_url],
        update_samples: args[:update_samples],
        email_notification: args[:email_notification],
        samples_workflow_executions_attributes: args[:samples_workflow_executions_attributes]
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
  end
end
