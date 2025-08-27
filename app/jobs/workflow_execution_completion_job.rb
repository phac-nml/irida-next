# frozen_string_literal: true

# Queues the workflow execution completion job
class WorkflowExecutionCompletionJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 10

  def perform(workflow_execution)
    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(workflow_execution, [:completing], validate_run_id: false)
      return handle_error_state_and_clean(workflow_execution)
    end

    result = WorkflowExecutions::CompletionService.new(workflow_execution).execute
    if result
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    else
      handle_unable_to_process_job(workflow_execution, self.class.name)
    end
  end
end
