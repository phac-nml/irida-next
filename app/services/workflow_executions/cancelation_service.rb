# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Cancel a WorkflowExecution
  class CancelationService < BaseService
    def initialize(workflow_execution, user = nil, params = {}, conn_override = nil)
      super(user, params)

      @workflow_execution = workflow_execution
      wes_connection = conn_override || Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false unless @workflow_execution.canceling?

      @wes_client.cancel_run(@workflow_execution.run_id)
    end
  end
end
