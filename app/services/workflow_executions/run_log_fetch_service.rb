# frozen_string_literal: true

module WorkflowExecutions
  # Service used to fetch logs for a WorkflowExecution
  class RunLogFetchService < BaseService
    def initialize(workflow_execution, user = nil, params = {}, conn_override = nil)
      super(user, params)

      @workflow_execution = workflow_execution
      wes_connection = conn_override || Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
    end

    def execute
      return { stdout: nil, stderr: nil } unless @workflow_execution.completed? || @workflow_execution.error?

      response = @wes_client.get_run_log(@workflow_execution.run_id)
      run_log = response[:run_log]

      stdout = resolve_log_output(run_log, :stdout)
      stderr = resolve_log_output(run_log, :stderr)

      { stdout: stdout, stderr: stderr }
    end

    private

    def resolve_log_output(run_log, key)
      output = run_log[key]
      uri = URI.parse(output)
      fetch_endpoint(uri.path)
    rescue URI::InvalidURIError, TypeError
      output
    end

    def fetch_endpoint(endpoint)
      @wes_client.get_endpoint(endpoint)
    rescue Integrations::ApiExceptions::NotFoundError => e
      Rails.logger.info(
        "WES #{endpoint} endpoint unavailable for run_id=#{@workflow_execution.run_id}: #{e.message}"
      )
      nil
    end
  end
end
