# frozen_string_literal: true

# Perform actions required to cancel a workflow execution
class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :exponentially_longer, attempts: Float::INFINITY

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, attempts: 3 do |job, exception|
    workflow_execution = job.arguments[0]

    # Errors 401 and 403 can mean that the run was actually completed
    # So we check the run status to check if it's completed or an actual error
    if [401, 403].contains? exception.http_error_code
      # get actual status from wes client
      wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
      status = wes_client.get_run_status(@workflow_execution.run_id)

      if status[:state] == 'COMPLETE'
        workflow_execution.state = 'canceled'
        workflow_execution.save
        return
      end
    end

    workflow_execution.state = 'error'
    workflow_execution.error_code = exception.http_error_code
    workflow_execution.save
  end

  def perform(workflow_execution, user)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute
  end
end
