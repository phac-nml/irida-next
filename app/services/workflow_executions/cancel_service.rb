# frozen_string_literal: true

module WorkflowExecutions
  # Service used to initiate the cancelation of a WorkflowExecution
  class CancelService < BaseService
    def initialize(workflow_execution, user = nil)
      super(user, {})
      @workflow_execution = workflow_execution
    end

    def execute # rubocop:disable Metrics/MethodLength
      return false unless @workflow_execution.cancellable?

      authorize! @workflow_execution, to: :cancel?

      if @workflow_execution.sent_to_ga4gh?
        # Schedule a job to cancel the run on the ga4gh wes server
        @workflow_execution.state = :canceling
        @workflow_execution.save
        WorkflowExecutionCancelationJob.set(
          queue: :waitable_queue
        ).perform_later(@workflow_execution, current_user)
      elsif @workflow_execution.initial?
        # No files to clean up, mark as cleaned and do not create a cleanup job.
        @workflow_execution.state = :canceled
        @workflow_execution.cleaned = true
        @workflow_execution.save
      else # state = :prepared
        # Files were generated but not sent to ga4gh, schedule a cleanup job
        @workflow_execution.state = :canceled
        @workflow_execution.save
        WorkflowExecutionCleanupJob.set(
          queue: :waitable_queue
        ).perform_later(@workflow_execution)
      end

      @workflow_execution
    end
  end
end
