# frozen_string_literal: true

module WorkflowExecutions
  # Service used to initiate the cancelation of a WorkflowExecution
  class CancelService < BaseService
    def initialize(workflow_execution, user = nil)
      super(user, {})
      @workflow_execution = workflow_execution
    end

    def execute
      return false unless @workflow_execution.cancellable?

      @workflow_execution.state = 'canceling'

      return unless @workflow_execution.save

      WorkflowExecutionCancelationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)

      @workflow_execution
    end
  end
end
