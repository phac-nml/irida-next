# frozen_string_literal: true

module WorkflowExecutions
  # Service used to update the status of a WorkflowExecution
  class StatusService < BaseService
    CANCELATION_STATES = %w[
      CANCELED CANCELING PREEMPTED
    ].freeze

    ERROR_STATES = %w[
      EXECUTOR_ERROR SYSTEM_ERROR
    ].freeze

    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return if @workflow_execution.run_id.nil?

      run_status = @wes_client.get_run_status(@workflow_execution.run_id)

      state = run_status[:state]

      @workflow_execution.state = 'complete' if state == 'COMPLETE'

      @workflow_execution.state = 'canceled' if CANCELATION_STATES.include?(state)

      @workflow_execution.state = 'error' if ERROR_STATES.include?(state)

      @workflow_execution.save

      @workflow_execution
    end
  end
end
