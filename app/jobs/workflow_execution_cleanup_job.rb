# frozen_string_literal: true

# cleans up workflow execution files no longer needed after completion
class WorkflowExecutionCleanupJob < ApplicationJob
  queue_as :default
  queue_with_priority 30

  def perform(workflow_execution)
    return unless workflow_execution.completed? ||
                  workflow_execution.canceled? ||
                  workflow_execution.error?

    workflow_execution = WorkflowExecutions::CleanupService.new(workflow_execution).execute

    raise_error('Attempted to clean Workflow Execution that is already cleaned.') unless workflow_execution
  end
end
