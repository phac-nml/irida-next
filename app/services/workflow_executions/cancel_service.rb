# frozen_string_literal: true

module WorkflowExecutions
  class CancelService < BaseService
    def initialize(workflow_execution, user = nil)
      super(user, {})
      @workflow_execution = workflow_execution
    end

    def execute
      return false unless @workflow_execution.state != 'Canceled'

      @workflow_execution.state = 'canceling'
      @workflow_execution.save

      return unless @workflow_execution.save

      WorkflowExecutionCancelationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)

      @workflow_execution
    end
  end
end
