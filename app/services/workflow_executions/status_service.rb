# frozen_string_literal: true

module WorkflowExecutions
  # Service used to update the status of a WorkflowExecution
  class StatusService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false if @workflow_execution.run_id.nil?

      run_status = @wes_client.get_run_status(@workflow_execution.run_id)

      state = run_status[:state]

      @workflow_execution.state = 'completing' if state == 'COMPLETE'

      if Integrations::Ga4ghWesApi::V1::States::CANCELATION_STATES.include?(state)
        @workflow_execution.state = 'canceled'
      end

      @workflow_execution.state = 'error' if Integrations::Ga4ghWesApi::V1::States::ERROR_STATES.include?(state)

      @workflow_execution.save

      # @workflow_execution.save do
      #   if @workflow_execution.email_notification && @workflow_execution.error?
      #     PipelineMailer.error_email(@workflow_execution).deliver_later
      #   end
      # end

      @workflow_execution
    end
  end
end
