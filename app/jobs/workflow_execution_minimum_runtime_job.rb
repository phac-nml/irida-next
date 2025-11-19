# frozen_string_literal: true

# Job to check if minimum time has elapsed before queueing a status check job for a workflow execution
class WorkflowExecutionMinimumRuntimeJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 10

  def perform(workflow_execution) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if workflow_execution.canceling? || workflow_execution.canceled? || workflow_execution.nil?

    min_run_time = minimum_run_time(workflow_execution)
    running_state = false

    running_state = workflow_execution_state(workflow_execution) unless min_run_time.nil?

    time_elapsed = Time.now.to_i - workflow_execution.created_at.to_i

    interval = status_check_interval(workflow_execution)

    # Check if the condition is met
    if !min_run_time.nil? && running_state && (time_elapsed >= min_run_time)
      # Condition met: process the object
      WorkflowExecutionStatusJob.set(
        wait_until: interval.seconds.from_now
      ).perform_later(workflow_execution)
    else
      # Condition not met: re-enqueue the job with a delay
      delay = [min_run_time - time_elapsed, interval].max
      WorkflowExecutionMinimumRuntimeJob.set(wait_until: delay.seconds.from_now).perform_later(workflow_execution)
    end
  end

  def workflow_execution_state(workflow_execution)
    running_state = false
    wes_connection = Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
    wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    status = wes_client.get_run_status(workflow_execution.run_id)
    running_state = true if status[:state] == 'RUNNING'

    running_state
  end
end
