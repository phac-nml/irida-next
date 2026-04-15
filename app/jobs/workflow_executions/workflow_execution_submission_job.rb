# frozen_string_literal: true

module WorkflowExecutions
  # Creates a wes connection and calls the submission service for the workflow execution
  class WorkflowExecutionSubmissionJob < WorkflowExecutionJob
    include ActiveJob::Continuable

    queue_as :default
    queue_with_priority 5

    # When server is unreachable, continually retry
    retry_on Integrations::ApiExceptions::ConnectionError, wait: :polynomially_longer, attempts: Float::INFINITY

    # Puts workflow execution into error state and records the error code
    retry_on Integrations::ApiExceptions::APIExceptionError, wait: :polynomially_longer, attempts: 3 do |job, exception|
      workflow_execution = job.arguments[0]
      workflow_execution.state = :error
      workflow_execution.http_error_code = exception.http_error_code
      workflow_execution.save

      WorkflowExecutionCleanupJob.perform_later(workflow_execution)

      workflow_execution
    end

    def perform(workflow_execution)
      @workflow_execution = workflow_execution
      return if user_cancelled_run?

      step :query_and_update_state
      step :queue_next_job
    end

    def user_cancelled_run?
      # User signaled to cancel
      @workflow_execution.canceling? || @workflow_execution.canceled?
    end

    def query_and_update_state
      if validate_initial_state(@workflow_execution, [:prepared], validate_run_id: false)
        run_id = WorkflowExecutions::SubmissionService.new(@workflow_execution).execute

        update_state(:submitted, run_id: run_id)
      else
        update_state(:error)
      end
    end

    def queue_next_job
      return if @workflow_execution.state.to_sym == :error

      WorkflowExecutionStatusJob.set(
        wait_until: @workflow_execution.workflow.status_check_interval.seconds.from_now
      ).perform_later(@workflow_execution.reload)
    end
  end
end
