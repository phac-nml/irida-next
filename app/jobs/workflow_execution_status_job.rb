# frozen_string_literal: true

# Queues the workflow execution status job
class WorkflowExecutionStatusJob < WorkflowExecutionJob
  include ActiveJob::Continuable

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
    @workflow_execution = workflow_execution

    step :verify_initial_state
    step :query_state
    step :verify_new_state
    step :save_state
    step :queue_next_job
  end

  private

  def verify_initial_state
    # User signaled to cancel
    @invalid_initial_state = @workflow_execution.canceling? || @workflow_execution.canceled?

    return if @invalid_initial_state

    @invalid_initial_state = !validate_initial_state(@workflow_execution, nil, validate_run_id: true)

    handle_error_state_and_clean(@workflow_execution) if @invalid_initial_state
  end

  def query_state
    return if @invalid_initial_state

    @state = WorkflowExecutions::StatusService.new(@workflow_execution).execute
  end

  def verify_new_state
    return if @invalid_initial_state
    return unless @state.nil?

    handle_unable_to_process_job(@workflow_execution, self.class.name)
  end

  def save_state
    return if @invalid_initial_state
    return if @state.nil?

    return if @workflow_execution.state.to_sym == @state

    @workflow_execution.state = @state
    @workflow_execution.save
  end

  def queue_next_job
    return if @invalid_initial_state
    return if @state.nil?

    @workflow_execution.reload
    case @workflow_execution.state.to_sym
    when :canceled, :error
      WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
    when :completing
      WorkflowExecutionCompletionJob.perform_later(@workflow_execution)
    when :canceling # max run time exceeded
      WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @workflow_execution.submitter)
    else
      WorkflowExecutionStatusJob.set(
        wait_until: status_check_delay_time.seconds.from_now
      ).perform_later(@workflow_execution)
    end
  end

  def status_check_delay_time
    min_run_time = @workflow_execution.workflow.minimum_run_time(@workflow_execution.samples.count)
    if min_run_time.nil?
      @workflow_execution.workflow.status_check_interval
    else
      min_run_time
    end
  end
end
