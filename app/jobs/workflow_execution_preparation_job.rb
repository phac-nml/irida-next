# frozen_string_literal: true

# Queues the workflow execution submission job
class WorkflowExecutionPreparationJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 20

  def perform(workflow_execution)
    # User signaled to cancel
    return if workflow_execution.canceling? || workflow_execution.canceled?

    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(workflow_execution, [:initial], validate_run_id: false)
      return handle_error_state_and_clean(workflow_execution)
    end

    result = WorkflowExecutions::PreparationService.new(workflow_execution).execute

    if result
      WorkflowExecutionSubmissionJob.perform_later(workflow_execution)
    else
      handle_unable_to_process_job(workflow_execution, self.class.name)
    end

    # TODO: this job doesn't have any tests. Only the service has tests.
    # Tests should be added when job queuing from CompletionService is refactored into this job.
  end
end
