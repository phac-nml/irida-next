# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
      @storage_service = ActiveStorage::Blob.service
    end

    def execute
      return false if @workflow_execution.completed?

      # TODO: meat of the PR

      @workflow_execution.state = 'finalized'

      @workflow_execution.save

      @workflow_execution
    end
  end
end
