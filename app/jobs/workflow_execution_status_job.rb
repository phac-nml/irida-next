# frozen_string_literal: true

# Queues the workflow execution status job
class WorkflowExecutionStatusJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 5

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :polynomially_longer, attempts: Float::INFINITY

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, wait: :polynomially_longer, attempts: 3 do |job, exception|
    workflow_execution = job.arguments[0]
    workflow_execution.state = :error
    workflow_execution.http_error_code = exception.http_error_code
    workflow_execution.save

    WorkflowExecutionCleanupJob.perform_later(workflow_execution)

    workflow_execution
  end

  def perform(workflow_execution)
    # User signaled to cancel
    return if workflow_execution.canceling? || workflow_execution.canceled?

    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(workflow_execution, nil, validate_run_id: true)
      return handle_error_state_and_clean(workflow_execution)
    end

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    result = WorkflowExecutions::StatusService.new(workflow_execution, wes_connection).execute

    if result.nil?
      nil
    elsif result
      queue_next_job(workflow_execution.reload)
    else
      handle_unable_to_process_job(workflow_execution, self.class.name)
    end
  end

  def queue_next_job(workflow_execution)
    case workflow_execution.state.to_sym
    when :canceled, :error
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    when :completing
      WorkflowExecutionCompletionJob.perform_later(workflow_execution)
    else
      WorkflowExecutionStatusJob.set(
        wait_until: workflow_execution.workflow.status_check_interval.seconds.from_now
      ).perform_later(workflow_execution)
    end
  end
end
