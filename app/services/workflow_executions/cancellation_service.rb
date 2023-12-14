# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Cancel a WorkflowExecution
  class CancellationService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false unless @workflow_execution.state in ['submitted', 'running??'] # other states that can be cancelled?

      # throws exception if failed
      @wes_client.cancel_run(@workflow_execution.run_id)

      # mark workflow execution as cancelled
      @workflow_execution.state = 'cancelled'

      @workflow_execution.save
    end
  end
end
