# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class DestroyService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
    end

    def execute
      return unless @workflow_execution.completed? || @workflow_execution.error?

      @workflow_execution.destroy
    end
  end
end
