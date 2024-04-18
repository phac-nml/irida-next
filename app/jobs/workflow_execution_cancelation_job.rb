# frozen_string_literal: true

# Perform actions required to cancel a workflow execution
class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :exponentially_longer, attempts: Float::INFINITY

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :exponentially_longer, attempts: Float::INFINITY

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, wait: :exponentially_longer, attempts: 5 do |job, exception|
    workflow_execution = job.arguments[0]
    workflow_execution.state = 'error'
    workflow_execution.error_code = exception.http_error_code
    workflow_execution.save!
  end

  # TODO: retry on 401
  # TODO: retry on 403
  # TODO: edge case where canceling a workflow that is actually completed (delay caused)
  # expects 401/403. Sapporo responds with 200
  # Need to check run status in retry block

  def perform(workflow_execution, user)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute
  end
end
