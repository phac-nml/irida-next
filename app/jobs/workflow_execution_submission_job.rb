# frozen_string_literal: true

# Creates a wes connection and calls the submission service for the workflow execution
class WorkflowExecutionSubmissionJob < ApplicationJob
  queue_as :default

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :polynomially_longer, attempts: Float::INFINITY

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, wait: :polynomially_longer, attempts: 3 do |job, exception|
    workflow_execution = job.arguments[0]
    workflow_execution.state = :error
    workflow_execution.http_error_code = exception.http_error_code
    workflow_execution.save

    WorkflowExecutionCleanupJob.set(queue: :waitable_queue).perform_later(workflow_execution)

    workflow_execution
  end

  def perform(workflow_execution)
    return if workflow_execution.canceling? || workflow_execution.canceled?

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::SubmissionService.new(workflow_execution, wes_connection).execute

    return if workflow_execution.run_id.nil?

    WorkflowExecutionStatusJob.set(queue: :waitable_queue,
                                   wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
