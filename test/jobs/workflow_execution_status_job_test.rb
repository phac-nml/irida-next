# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionStatusJobTest < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_submitted)
    @stubs = faraday_test_adapter_stubs
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'successful job execution' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 1)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      @stubs.get("/runs/#{@workflow_execution.run_id}/status") do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          {
            run_id: @workflow_execution.run_id,
            state: 'COMPLETE'
          }
        ]
      end

      perform_enqueued_jobs(only: WorkflowExecutionStatusJob) do
        WorkflowExecutionStatusJob.perform_later(@workflow_execution)
      end
    end

    assert_performed_jobs 1
    assert @workflow_execution.reload.completing?
  end

  test 'repeated connection errors' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 6)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/status"
      @stubs.get(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.get(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.get(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.get(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.get(endpoint) { |_env| raise Faraday::ConnectionFailed }
      # a success after 5 attempts
      @stubs.get(endpoint) do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          {
            run_id: @workflow_execution.run_id,
            state: 'COMPLETE'
          }
        ]
      end

      WorkflowExecutionStatusJob.perform_later(@workflow_execution)
      perform_enqueued_jobs_one_at_a_time(only_class: WorkflowExecutionStatusJob)
    end

    assert_performed_jobs 6
    assert @workflow_execution.reload.completing?
  end
end
