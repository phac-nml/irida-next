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
      return { stdout: nil, stderr: nil } unless @workflow_execution.completed? || @workflow_execution.error?

      stdout = fetch_run_output(:stdout)
      stderr = fetch_run_output(:stderr)

      return { stdout: stdout, stderr: stderr } if stdout || stderr

      log = @wes_client.get_run_log(@workflow_execution.run_id)
      { stdout: log[:run_log][:stdout], stderr: log[:run_log][:stderr] }
    end

    private

    def fetch_run_output(stream)
      @wes_client.public_send("get_run_#{stream}", @workflow_execution.run_id)
    rescue Integrations::ApiExceptions::NotFoundError => e
      Rails.logger.info(
        "WES #{stream} endpoint unavailable for run_id=#{@workflow_execution.run_id}: #{e.message}"
      )
      nil
    end
  end
end
