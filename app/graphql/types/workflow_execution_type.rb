# frozen_string_literal: true

module Types
  # WorkflowExecutions Type
  class WorkflowExecutionType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A workflow execution'

    field :blob_run_directory, String, null: true, description: 'WorkflowExecution blob run directory'
    field :cleaned, Boolean, null: false, description: 'WorkflowExecution cleaned status'
    field :http_error_code, Integer, null: true, description: 'WorkflowExecution http error code'
    field :metadata,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata for the sample',
          resolver: Resolvers::WorkflowExecutionMetadataResolver
    field :name, String, null: true, description: 'WorkflowExecution name'
    field :namespace,
          NamespaceType,
          null: true,
          description: 'Namespace ID of the workflow execution',
          resolver: Resolvers::WorkflowExecutionNamespaceResolver
    # field :namespace_id, String
    field :run_id, String, null: true, description: 'WorkflowExecution run id'
    field :samples,
          SampleType.connection_type,
          null: true,
          description: 'Samples on the workflow execution',
          complexity: 5,
          resolver: Resolvers::SamplesWorkflowExecutionsResolver
    field :state, String, null: true, description: 'WorkflowExecution state'
    field :submitter, UserType, null: false, description: 'WorkflowExecution submitter (User)'
    field :submitter_id, String, null: true, description: 'WorkflowExecution submitter_id'
    field :tags, GraphQL::Types::JSON, null: true, description: 'WorkflowExecution tags'

    field :workflow_engine, String, null: true, description: 'WorkflowExecution workflow engine'
    field :workflow_engine_parameters, GraphQL::Types::JSON, null: true,
                                                             description: 'WorkflowExecution workflow engine parameters'
    field :workflow_engine_version, String, null: true, description: 'WorkflowExecution workflow engine version' # rubocop:disable GraphQL/ExtractType
    field :workflow_params, GraphQL::Types::JSON, null: true, description: 'WorkflowExecution params'
    field :workflow_type, String, null: true, description: 'WorkflowExecution type'
    field :workflow_type_version, String, null: true, description: 'WorkflowExecution type version'
    field :workflow_url, String, null: true, description: 'WorkflowExecution url' # rubocop:disable GraphQL/ExtractType

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user] }
        )
    end
  end
end
