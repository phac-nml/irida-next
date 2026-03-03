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
    return if user_cancelled_run?

    step :query_and_update_state
    step :queue_next_job
  end

  private

  def query_and_update_state
    if validate_initial_state(@workflow_execution, nil, validate_run_id: true)
      state = WorkflowExecutions::StatusService.new(@workflow_execution).execute

      if state.nil?
        state = :error
        Rails.logger.error(
          I18n.t('activerecord.errors.models.workflow_execution.invalid_job_state', job_name: self.class.name)
        )
      end
    else
      state = :error
    end

    update_state(state)
  end

  def user_cancelled_run?
    # User signaled to cancel
    @workflow_execution.canceling? || @workflow_execution.canceled?
  end

  def update_state(state)
    return if @workflow_execution.state.to_sym == state

    @workflow_execution.state = state
    @workflow_execution.save!
  end

  def queue_next_job
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
