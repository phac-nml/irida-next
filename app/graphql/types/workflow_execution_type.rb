# frozen_string_literal: true

module Types
  # WorkflowExecutions Type
# rubocop:disable convention:GraphQL/ExtractType
  class WorkflowExecutionType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'A workflow execution'

    field :cleaned, Boolean, null: false, description: 'WorkflowExecution cleaned status'
    field :group, GroupType, null: true, description: 'Group, if the workflow belongs to a group namespace'
    field :http_error_code, Integer, null: true, description: 'WorkflowExecution http error code'
    field :metadata,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata for the sample',
          resolver: Resolvers::WorkflowExecutionMetadataResolver
    field :name, String, null: true, description: 'WorkflowExecution name'
    field :project, ProjectType, null: true, description: 'Project, if the workflow belongs to a project namespace'
    field :run_id, String, null: true, description: 'WorkflowExecution run id'
    field :samples_workflow_executions,
          [SamplesWorkflowExecutionType],
          null: true,
          description: 'SamplesWorkflowExecutions on the workflow execution',
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

    def project
      return object.namespace.project if object.namespace.is_a? Namespaces::ProjectNamespace

      nil
    end

    def group
      return object.namespace if object.namespace.is_a? Group

      nil
    end

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
