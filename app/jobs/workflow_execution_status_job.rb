# frozen_string_literal: true

# Queues the workflow execution status job
class WorkflowExecutionStatusJob < ApplicationJob
  queue_as :default

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

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::StatusService.new(workflow_execution, wes_connection).execute

    case workflow_execution.state.to_sym
    when :canceled, :error
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    when :completing
      WorkflowExecutionCompletionJob.perform_later(workflow_execution)
    else
      WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now)
                                .perform_later(workflow_execution)
    end
  end
end
