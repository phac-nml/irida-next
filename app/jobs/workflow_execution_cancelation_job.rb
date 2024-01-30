# frozen_string_literal: true

class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution, user)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute

    # return if workflow_execution.canceled?
    #
    # WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
