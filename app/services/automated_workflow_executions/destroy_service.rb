# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Destroy an AutomatedWorkflowExecution
  class DestroyService < BaseService
    attr_accessor :automated_workflow_execution

    def initialize(automated_workflow_execution, user = nil, params = {})
      super(user, params)
      @automated_workflow_execution = automated_workflow_execution
    end

    def execute
      authorize! @automated_workflow_execution.namespace, to: :destroy_automated_workflow_execution?

      @automated_workflow_execution.destroy
    end
  end
end
