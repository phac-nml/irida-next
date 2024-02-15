# frozen_string_literal: true

# Perform actions required to cancel a workflow execution
class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution, user)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute
  end
end
