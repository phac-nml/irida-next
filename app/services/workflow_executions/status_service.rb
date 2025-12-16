# frozen_string_literal: true

module WorkflowExecutions
  # Service used to update the status of a WorkflowExecution
  class StatusService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return false if @workflow_execution.run_id.nil?

      run_status = @wes_client.get_run_status(@workflow_execution.run_id)

      state = run_status[:state]

      return nil if delay_status_check?(run_status)

      new_state = if state == 'RUNNING'
                    :running
                  elsif state == 'COMPLETE'
                    :completing
                  elsif Integrations::Ga4ghWesApi::V1::States::CANCELATION_STATES.include?(state)
                    :canceled
                  elsif Integrations::Ga4ghWesApi::V1::States::ERROR_STATES.include?(state)
                    :error
                  end

      workflow_execution_system_cancellation = max_run_time_exceeded_cancel? if new_state == :running

      return nil if workflow_execution_system_cancellation

      @workflow_execution.state = new_state unless new_state.nil?

      @workflow_execution.save
    end

    private

    def delay_status_check?(run_status)
      return false if @workflow_execution.reload.state.to_sym == :running

      return false unless run_status[:state] == 'RUNNING'

      @workflow_execution.state = :running
      @workflow_execution.save

      min_run_time = @workflow_execution.workflow.minimum_run_time(@workflow_execution.samples.count)
      if min_run_time.nil?
        false
      else
        WorkflowExecutionStatusJob.set(wait_until: min_run_time.seconds.from_now).perform_later(@workflow_execution)
        true
      end
    end

    def max_run_time_exceeded_cancel?
      run_time = @workflow_execution.workflow.state_time_calculation(@workflow_execution, :running)
      maximum_run_time = @workflow_execution.workflow.maximum_run_time(@workflow_execution.samples.count)

      # Max runtime for pipeline (in running state) has exceeded so a cancellation request to WES is made
      unless @workflow_execution.cancellable? && maximum_run_time && run_time && (run_time > maximum_run_time)
        return false
      end

      @workflow_execution.state = :canceling
      @workflow_execution.save
      WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @workflow_execution.submitter)
      true
    end
  end
end
