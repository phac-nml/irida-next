# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Cleanup a WorkflowExecution
  class CleanupService < BaseService
    def initialize(workflow_execution, user = nil, params = {}, conn_override = nil)
      super(user, params)

      @workflow_execution = workflow_execution
      wes_connection = conn_override || Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return { run_log: nil, run_stdout: nil } unless @workflow_execution.completed? || @workflow_execution.error?

      run_log = @wes_client.get_run_log(@workflow_execution.run_id)
      run_stdout = fetch_run_stdout

      { run_log: run_log, run_stdout: run_stdout }
    end

    private

    def fetch_run_stdout
      @wes_client.get_run_stdout(@workflow_execution.run_id)
    rescue Integrations::ApiExceptions::NotFoundError => e
      Rails.logger.info(
        "WES stdout endpoint unavailable for run_id=#{@workflow_execution.run_id}: #{e.message}"
      )
      nil
    end
  end
end
