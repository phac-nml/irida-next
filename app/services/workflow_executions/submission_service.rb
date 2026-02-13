# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class SubmissionService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false unless @workflow_execution.prepared?

      run = @wes_client.run_workflow(**@workflow_execution.as_wes_params)

      run[:run_id]
    end
  end
end
