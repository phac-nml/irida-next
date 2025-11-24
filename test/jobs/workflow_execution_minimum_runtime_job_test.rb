# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionSubmissionJobTest < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_submitted)
    @stubs = faraday_test_adapter_stubs
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'workflow submission minimum run time before status check' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 2)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/status"
      puts endpoint
      @stubs.get(endpoint) do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          {
            run_id: @workflow_execution.run_id,
            state: 'RUNNING'
          }
        ]
      end

      perform_enqueued_jobs(only: WorkflowExecutionMinimumRuntimeJob) do
        WorkflowExecutionMinimumRuntimeJob.perform_later(@workflow_execution)
      end
    end

    # assert_enqueued_jobs(1, only: WorkflowExecutionStatusJob)
    # assert_performed_jobs(1, only: WorkflowExecutionSubmissionJob)
    assert_performed_jobs(1, only: WorkflowExecutionMinimumRuntimeJob)
    assert @workflow_execution.reload.running?
  end
end
