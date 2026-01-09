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

      new_state = if state == 'RUNNING'
                    if max_run_time_exceeded_cancel?(@workflow_execution.workflow)
                      :canceling
                    else
                      :running
                    end
                  elsif state == 'COMPLETE'
                    :completing
                  elsif Integrations::Ga4ghWesApi::V1::States::CANCELATION_STATES.include?(state)
                    :canceled
                  elsif Integrations::Ga4ghWesApi::V1::States::ERROR_STATES.include?(state)
                    :error
                  end

      @workflow_execution.state = new_state unless new_state.nil?

      @workflow_execution.save
    end

    private

    # Send cancellation request to WES if pipeline has exceeded maximum runtime, if set
    def max_run_time_exceeded_cancel?(pipeline)
      run_time = pipeline.state_time_calculation(@workflow_execution, :running)
      maximum_run_time = pipeline.maximum_run_time(@workflow_execution.samples.count)

      return false unless maximum_run_time && run_time && (run_time > maximum_run_time)

      true
    end
  end
end
