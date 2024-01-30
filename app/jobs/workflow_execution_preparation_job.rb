# frozen_string_literal: true

# Queues the workflow execution submission job
class WorkflowExecutionPreparationJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    return unless workflow_execution.canceling? || workflow_execution.canceled?
    return unless WorkflowExecutions::PreparationService.new(workflow_execution).execute

    WorkflowExecutionSubmissionJob.set(wait_until: 30.seconds.from_now).perform_later(workflow_execution)
  end
end
