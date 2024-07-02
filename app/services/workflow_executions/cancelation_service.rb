# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Cancel a WorkflowExecution
  class CancelationService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return false unless @workflow_execution.canceling?

      @wes_client.cancel_run(@workflow_execution.run_id)

      # mark workflow execution as canceled
      @workflow_execution.state = :canceled

      @workflow_execution.save

      # Jobs in the initial state have no file to cleanup
      unless @workflow_execution.initial?
        WorkflowExecutionCleanupJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
      end

      @workflow_execution
    end
  end
end
