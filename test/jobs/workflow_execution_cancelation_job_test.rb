# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionCancelationJobTest < ActiveJobTestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_canceling)
    @user = users(:john_doe)
    @stubs = faraday_test_adapter_stubs
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'successful job execution' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 1)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      @stubs.post("/runs/#{@workflow_execution.run_id}/cancel") do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @workflow_execution.run_id }
        ]
      end

      perform_enqueued_jobs(only: WorkflowExecutionCancelationJob) do
        WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @user)
      end
    end

    assert_performed_jobs 1
    assert @workflow_execution.reload.canceled?
  end

  test 'repeated connection errors' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 6)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/cancel"
      @stubs.post(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.post(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.post(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.post(endpoint) { |_env| raise Faraday::ConnectionFailed }
      @stubs.post(endpoint) { |_env| raise Faraday::ConnectionFailed }
      # a success after 5 failed attempts
      @stubs.post(endpoint) do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @workflow_execution.run_id }
        ]
      end

      WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @user)
      perform_enqueued_jobs_one_at_a_time(only_class: WorkflowExecutionCancelationJob)
    end

    assert_performed_jobs 6
    assert @workflow_execution.reload.canceled?
  end

  test 'repeated api exception errors' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 3)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/cancel"
      @stubs.post(endpoint) { |_env| raise Faraday::BadRequestError }
      @stubs.post(endpoint) { |_env| raise Faraday::BadRequestError }
      @stubs.post(endpoint) { |_env| raise Faraday::BadRequestError }
      # a success (never reached) after 3 failed attempts
      @stubs.post(endpoint) do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @workflow_execution.run_id }
        ]
      end

      WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @user)
      perform_enqueued_jobs_one_at_a_time(only_class: WorkflowExecutionCancelationJob)
    end

    assert_performed_jobs 3
    @workflow_execution.reload
    assert @workflow_execution.error?
    assert @workflow_execution.http_error_code == 400
  end

  test 'api exception error then a success' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 2)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      endpoint = "/runs/#{@workflow_execution.run_id}/cancel"
      @stubs.post(endpoint) { |_env| raise Faraday::BadRequestError }
      # a success after 1 failed attempt
      @stubs.post(endpoint) do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @workflow_execution.run_id }
        ]
      end

      WorkflowExecutionCancelationJob.perform_later(@workflow_execution, @user)
      perform_enqueued_jobs_one_at_a_time(only_class: WorkflowExecutionCancelationJob)
    end

    assert_performed_jobs 2
    assert @workflow_execution.reload.canceled?
  end
end
