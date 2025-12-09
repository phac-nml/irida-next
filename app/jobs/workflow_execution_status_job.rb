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

  def perform(workflow_execution, min_run_time = nil)
    # User signaled to cancel
    return if workflow_execution.canceling? || workflow_execution.canceled?

    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(workflow_execution, nil, validate_run_id: true)
      return handle_error_state_and_clean(workflow_execution)
    end

    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn

    return if min_run_time && delay_status_check?(wes_connection, workflow_execution, min_run_time)

    result = WorkflowExecutions::StatusService.new(workflow_execution, wes_connection).execute

    if result
      queue_next_job(workflow_execution.reload, min_run_time)
    else
      handle_unable_to_process_job(workflow_execution, self.class.name)
    end
  end

  # Delay the status check if the workflow is in running state and minimum run time has not been reached
  def delay_status_check?(wes_connection, workflow_execution, min_run_time)
    return false if workflow_execution.reload.state == 'running'

    wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    status = wes_client.get_run_status(workflow_execution.run_id)

    return false unless status[:state] == 'RUNNING'

    workflow_execution.state = :running
    workflow_execution.save

    WorkflowExecutionStatusJob.set(wait_until: min_run_time.seconds.from_now).perform_later(workflow_execution,
                                                                                            min_run_time)
    true
  end

  def queue_next_job(workflow_execution, min_run_time = nil)
    case workflow_execution.state.to_sym
    when :canceled, :error
      WorkflowExecutionCleanupJob.perform_later(workflow_execution)
    when :completing
      WorkflowExecutionCompletionJob.perform_later(workflow_execution)
    else
      requeue_or_cancel(workflow_execution, min_run_time)
    end
  end

  def requeue_or_cancel(workflow_execution, min_run_time = nil)
    run_time = state_time_calculation(workflow_execution, :running)
    maximum_run_time = maximum_run_time(workflow_execution)

    # Max runtime for pipeline (in running state) has exceeded so a cancellation request to WES is made
    if workflow_execution.cancellable? && maximum_run_time && run_time && (run_time > maximum_run_time)
      workflow_execution.state = :canceling
      workflow_execution.save
      WorkflowExecutionCancelationJob.perform_later(workflow_execution, workflow_execution.submitter)
    else
      WorkflowExecutionStatusJob.set(wait_until: status_check_interval(workflow_execution).seconds.from_now)
                                .perform_later(workflow_execution, min_run_time)
    end
  end
end
