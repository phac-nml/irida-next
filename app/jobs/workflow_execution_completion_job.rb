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

    WorkflowExecutions::CompletionService.new(workflow_execution).execute

    # TODO: this job doesn't have any tests. Only the service has tests.
    # Tests should be added when job queuing from CompletionService is refactored into this job.
  end
end
