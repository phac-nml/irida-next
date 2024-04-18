# frozen_string_literal: true

# Perform actions required to cancel a workflow execution
class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :exponentially_longer, attempts: Float::INFINITY

  # 401
  rescue_from Integrations::ApiExceptions::UnauthorizedError do |job, exception|
    handle_completed_run_errors(job, exception)
  end

  # 403
  rescue_from Integrations::ApiExceptions::ForbiddenError do |job, exception|
    handle_completed_run_errors(job, exception)
  end

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, wait: :exponentially_longer, attempts: 5 do |job, exception|
    workflow_execution = job.arguments[0]
    workflow_execution.state = 'error'
    workflow_execution.error_code = exception.http_error_code
    workflow_execution.save
  end

  def perform(workflow_execution, user)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute
  end

  private

  def handle_completed_run_errors(job, exception)
    # check status
    #
    # on completed, exit and set to canceled
    # workflow execution should not continue to completion steps
    #
    # otherwise, set error
    puts job.http_error_code
  end
end
