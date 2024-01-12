# frozen_string_literal: true

module Types
  # WorkflowExecutions Type
  class WorkflowExecutionType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A workflow execution'

    # TODO: should fields like this have extra types or is an array of strings good enough?
    field :metadata, [String], null: true, description: 'WorkflowExecution metadata'
    field :run_id, String, null: true, description: 'WorkflowExecution run id'
    field :state, String, null: true, description: 'WorkflowExecution state'
    field :submitter, UserType, null: false, description: 'WorkflowExecution submitter (User)'
    field :submitter_id, String, null: true, description: 'WorkflowExecution submitter_id'
    field :tags, [String], null: true, description: 'WorkflowExecution tags'

    field :workflow_engine, String, null: true, description: 'WorkflowExecution workflow engine'
    field :workflow_engine_parameters, [String], null: true, description: 'WorkflowExecution workflow engine parameters'
    field :workflow_engine_version, String, null: true, description: 'WorkflowExecution workflow engine version' # rubocop:disable GraphQL/ExtractType
    field :workflow_params, [String], null: true, description: 'WorkflowExecution params'
    field :workflow_type, String, null: true, description: 'WorkflowExecution type'
    field :workflow_type_version, String, null: true, description: 'WorkflowExecution type version'
    field :workflow_url, String, null: true, description: 'WorkflowExecution url' # rubocop:disable GraphQL/ExtractType

    field :samples,
          SampleType.connection_type,
          null: true,
          description: 'Samples on the workflow execution',
          complexity: 5,
          resolver: Resolvers::SamplesWorkflowExecutionsResolver

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object.submitter, # TODO: Should we display only for submitter? Should a WorkflowExecution policy be made?
          context: { user: context[:current_user] }
        )
    end
  end
end
