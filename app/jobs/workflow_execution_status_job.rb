# frozen_string_literal: true

# Queues the workflow execution status job
class WorkflowExecutionStatusJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    workflow_execution = WorkflowExecutions::StatusService.new(workflow_execution, wes_connection).execute

    return unless !workflow_execution.completed? && !workflow_execution.canceled? && !workflow_execution.error?

    WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
