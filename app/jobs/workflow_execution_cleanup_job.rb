# frozen_string_literal: true

# cleans up workflow execution files no longer needed after completion
class WorkflowExecutionCleanupJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 30

  def perform(workflow_execution)
    # Don't run service if already cleaned
    return if workflow_execution.nil? || workflow_execution.cleaned?

    # Only run service on runs that can be cleaned
    return unless workflow_execution.completed? ||
                  workflow_execution.canceled? ||
                  workflow_execution.error?

    # Final stage of WorkflowExecution life cycle. No further work required.
    WorkflowExecutions::CleanupService.new(workflow_execution).execute
  end
end
