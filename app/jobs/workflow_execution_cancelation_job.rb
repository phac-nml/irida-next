# frozen_string_literal: true

class WorkflowExecutionCancelationJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution, user)
    workflow_execution.state = 'canceling'
    workflow_execution.save
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    WorkflowExecutions::CancelationService.new(workflow_execution, wes_connection, user).execute
  end
end
