# frozen_string_literal: true

# Creates a wes connection and calls the submission service for the workflow execution
class WorkflowExecutionSubmissionJob < WorkflowExecutionJob
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
    # User signaled to cancel
    return if workflow_execution.canceling? || workflow_execution.canceled?

    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(workflow_execution, [:prepared], validate_run_id: true)
      return handle_error_state_and_clean(workflow_execution)
    end

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::SubmissionService.new(workflow_execution, wes_connection).execute

    WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
