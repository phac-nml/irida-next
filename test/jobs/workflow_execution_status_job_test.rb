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

    assert_performed_jobs(1)

    assert @workflow_execution.reload.completing?

    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_performed_jobs 1
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
      # a success after 5 failed attempts
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
      perform_enqueued_jobs_sequentially(delay_seconds: 4, only: WorkflowExecutionStatusJob)
    end

    assert_performed_jobs(6)

    assert @workflow_execution.reload.completing?

    assert_performed_jobs(6, only: WorkflowExecutionStatusJob)
    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
  end

  test 'repeated api exception errors' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 3)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/status"
      @stubs.get(endpoint) { |_env| raise Faraday::BadRequestError }
      @stubs.get(endpoint) { |_env| raise Faraday::BadRequestError }
      @stubs.get(endpoint) { |_env| raise Faraday::BadRequestError }
      # a success (never reached) after 3 failed attempts
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
      perform_enqueued_jobs_sequentially(delay_seconds: 4, only: WorkflowExecutionStatusJob)
    end

    assert_performed_jobs(3)

    @workflow_execution.reload
    assert @workflow_execution.error?
    assert @workflow_execution.http_error_code == 400

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(3, only: WorkflowExecutionStatusJob)
  end

  test 'api exception error then a success' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 2)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/status"
      @stubs.get(endpoint) { |_env| raise Faraday::BadRequestError }
      # a success after 1 failed attempt
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
      perform_enqueued_jobs_sequentially(delay_seconds: 4, only: WorkflowExecutionStatusJob)
    end

    assert_performed_jobs(2)

    assert @workflow_execution.reload.completing?

    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_performed_jobs(2, only: WorkflowExecutionStatusJob)
  end
end
