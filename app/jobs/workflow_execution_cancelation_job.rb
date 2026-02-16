# frozen_string_literal: true

# Perform actions required to cancel a workflow execution
class WorkflowExecutionCancelationJob < WorkflowExecutionJob
  include ActiveJob::Continuable

  queue_as :default
  queue_with_priority 5

  # When server is unreachable, continually retry
  retry_on Integrations::ApiExceptions::ConnectionError, wait: :polynomially_longer, attempts: Float::INFINITY

  # Puts workflow execution into error state and records the error code
  retry_on Integrations::ApiExceptions::APIExceptionError, wait: :polynomially_longer, attempts: 3 do |job, exception|
    workflow_execution = job.arguments[0]

    # Errors 401 and 403 can mean that the run was actually completed
    # So we check the run status to check if it's completed or an actual error
    if [401, 403].include? exception.http_error_code
      # get actual status from wes client
      wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
      status = wes_client.get_run_status(workflow_execution.run_id)

      if status[:state] == 'COMPLETE'
        workflow_execution.state = :canceled
        workflow_execution.save
        return
      end
    end

    workflow_execution.state = :error
    workflow_execution.http_error_code = exception.http_error_code
    workflow_execution.save

    WorkflowExecutionCleanupJob.perform_later(workflow_execution)
  end

  def perform(workflow_execution, user)
    @workflow_execution = workflow_execution
    @user = user

    step :submit_cancelation
    step :update_state_step
    step :queue_next_job
  end

  def submit_cancelation
    # validate workflow_execution object is fit to run jobs on
    unless validate_initial_state(@workflow_execution, [:canceling], validate_run_id: true)
      update_state(:error, force: true)
      return
    end

    WorkflowExecutions::CancelationService.new(@workflow_execution, @user).execute
  end

  def update_state_step
    return if @workflow_execution.state.to_sym == :error

    update_state(:canceled)
  end

  def update_state(state, force: false)
    return if @workflow_execution.state.to_sym == state

    if force
      # validation must be skipped in the case where model is already invalid (e.g. no namespace)
      @workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    else
      @workflow_execution.state = state
      @workflow_execution.save
    end
  end

  def queue_next_job
    return if @workflow_execution.state.to_sym == :error

    WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
  end
end
