# frozen_string_literal: true

module WorkflowExecutions
  # Service used to update the status of a WorkflowExecution
  class StatusService < BaseService
    def initialize(workflow_execution, user = nil, params = {}, conn_override = nil)
      super(user, params)

      @workflow_execution = workflow_execution
      wes_connection = conn_override || Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/AbcSize
      return false if @workflow_execution.run_id.nil?

      run_status = @wes_client.get_run_status(@workflow_execution.run_id)
      state = run_status[:state]

      if Integrations::Ga4ghWesApi::V1::States::RUNNING_STATES.include?(state)
        # Send cancellation request to WES if pipeline has exceeded maximum runtime, if set
        if max_run_time_exceeded_cancel?(@workflow_execution.workflow)
          :canceling
        else
          :running
        end
      elsif Integrations::Ga4ghWesApi::V1::States::SUBMITTED_STATES.include?(state)
        :submitted
      elsif state == 'COMPLETE'
        :completing
      elsif Integrations::Ga4ghWesApi::V1::States::CANCELATION_STATES.include?(state)
        :canceled
      elsif state == 'UNKNOWN'
        if @workflow_execution.state.to_sym == :submitted
          :submitted
        else
          :error
        end
      elsif Integrations::Ga4ghWesApi::V1::States::ERROR_STATES.include?(state)
        :error
      elsif Integrations::Ga4ghWesApi::V1::States::VALID_STATES.exclude?(state)
        Rails.logger.error("Could not process state '#{state}' returned by WES client. Full response:  #{run_status}")
        nil
      else
        # This should never happen. This is for execution safety.
        # If it does happen, the states.rb file no longer aligns with the states defined in this function.
        Rails.logger.error("State '#{state}' is not explicitly handled in StatusService, defaulting to previous state")
        @workflow_execution.state.to_sym
      end
    end

    private

    def max_run_time_exceeded_cancel?(pipeline)
      run_time = pipeline.state_time_calculation(@workflow_execution, :running)
      maximum_run_time = pipeline.maximum_run_time(@workflow_execution.samples.count)

      return false unless maximum_run_time && run_time && (run_time > maximum_run_time)

      true
    end
  end
end
