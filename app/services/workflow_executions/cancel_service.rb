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

      authorize! @workflow_execution, to: :cancel?

      # Early exit if workflow execution has not been submitted to ga4gh wes yet
      unless @workflow_execution.sent_to_ga4gh?
        @workflow_execution.state = :canceled
        @workflow_execution.save

        unless Rails.application.config.disable_workflow_execution_cleanup_job
          WorkflowExecutionCleanupJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
        end

        return @workflow_execution
      end

      @workflow_execution.state = :canceling
      @workflow_execution.save

      WorkflowExecutionCancelationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution,
                                                                                         current_user)

      @workflow_execution
    end
  end
end
