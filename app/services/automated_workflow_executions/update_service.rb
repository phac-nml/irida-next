# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Update an AutomatedWorkflowExecution
  class UpdateService < BaseService
    attr_accessor :automated_workflow_execution

    def initialize(automated_workflow_execution, user = nil, params = {})
      super(user, params)
      @automated_workflow_execution = automated_workflow_execution
    end

    def execute
      authorize! @automated_workflow_execution.namespace, to: :update_automated_workflow_execution?

      @automated_workflow_execution.update(params)
    end
  end
end
