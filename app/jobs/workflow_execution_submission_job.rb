# frozen_string_literal: true

# Queues the workflow execution submission job
class WorkflowExecutionSubmissionJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    # wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    # WorkflowExecutions::SubmissionService.new(workflow_execution, wes_connection).execute
  end
end
