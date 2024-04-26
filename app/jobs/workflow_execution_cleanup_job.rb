# frozen_string_literal: true

# cleans up workflow execution files no longer needed after completion
class WorkflowExecutionCleanupJob < ApplicationJob
  queue_as :default

  def perform(workflow_execution)
    return unless workflow_execution.completed? ||
                  workflow_execution.canceled? ||
                  workflow_execution.deleted? ||
                  workflow_execution.error?

    WorkflowExecutions::CleanupService.new(workflow_execution).execute
  end
end
