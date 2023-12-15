# frozen_string_literal: true

# Creates a wes connection and calls the submission service for the workflow execution
class WorkflowExecutionSubmissionJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    # wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    # WorkflowExecutions::SubmissionService.new(workflow_execution, wes_connection).execute
  end
end
