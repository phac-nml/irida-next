# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Update an AutomatedWorkflowExecution
  class UpdateService < BaseService
    attr_accessor :automated_workflow_execution

    class AutomatedWorkflowExecutionsUpdateError < StandardError
    end

    def initialize(automated_workflow_execution, user = nil, params = {})
      super(user, params)
      @automated_workflow_execution = automated_workflow_execution
    end

    def execute
      validate_project_not_archived(@automated_workflow_execution.namespace)
      authorize! @automated_workflow_execution.namespace, to: :update_automated_workflow_executions?

      @automated_workflow_execution.update(params)
    rescue AutomatedWorkflowExecutions::UpdateService::AutomatedWorkflowExecutionsUpdateError => e
      @automated_workflow_execution.errors.add(:base, e.message)
      @automated_workflow_execution
    end
  end
end
