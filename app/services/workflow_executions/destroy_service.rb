# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class DestroyService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
    end

    def execute
      return unless @workflow_execution.submitter == current_user && @workflow_execution.deletable?

      @workflow_execution.destroy
    end
  end
end
