# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Create a new AutomatedWorkflowExecution
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super
    end

    def execute
      @automated_workflow_execution = AutomatedWorkflowExecution.new(params.merge(created_by: current_user))
      namespace = @automated_workflow_execution.namespace

      authorize! namespace, to: :create_automated_workflow_executions? if namespace.present?

      @automated_workflow_execution.save

      if @automated_workflow_execution.persisted?
        namespace.create_activity key: 'namespaces_project_namespace.automated_pipeline.create',
                                  owner: current_user,
                                  parameters: {
                                    automated_pipeline_id: @automated_workflow_execution.id,
                                    action: 'automated_pipeline_create'
                                  }
      end

      @automated_workflow_execution
    end
  end
end
