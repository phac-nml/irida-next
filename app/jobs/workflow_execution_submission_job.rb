# frozen_string_literal: true

# Creates a wes connection and calls the submission service for the workflow execution
class WorkflowExecutionSubmissionJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    return if workflow_execution.canceling? || workflow_execution.canceled?

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::SubmissionService.new(workflow_execution, wes_connection).execute

    return if workflow_execution.run_id.nil?

    WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
