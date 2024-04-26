# frozen_string_literal: true

module WorkflowExecutions
  # Service used to update the status of a WorkflowExecution
  class StatusService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      return false if @workflow_execution.run_id.nil?

      run_status = @wes_client.get_run_status(@workflow_execution.run_id)

      state = run_status[:state]

      new_state = if state == 'RUNNING'
                    :running
                  elsif state == 'COMPLETE'
                    :completing if state == 'COMPLETE'
                  elsif Integrations::Ga4ghWesApi::V1::States::CANCELATION_STATES.include?(state)
                    :canceled
                  elsif Integrations::Ga4ghWesApi::V1::States::ERROR_STATES.include?(state)
                    :error
                  end

      @workflow_execution.update(state: new_state) unless new_state.nil?

      @workflow_execution
    end
  end
end
