# frozen_string_literal: true

require 'test_helper'
require 'active_job_test_case'

class WorkflowExecutionStatusJobTest < ActiveJobTestCase
  def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @workflow_execution = workflow_executions(:irida_next_example_submitted)
    @stubs = faraday_test_adapter_stubs

    body = Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json')

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"a1Ab"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"b1Bc"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"c1Cd"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.1/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"d1De"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"e1Ef"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/iridanextexample/1.0.0/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"f1Fg"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/gasclustering/0.4.2/nextflow_schema.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"g1gh"]' })

    stub_request(:any, 'https://raw.githubusercontent.com/phac-nml/gasclustering/0.4.2/assets/schema_input.json')
      .to_return(status: 200, body:, headers: { etag: '[W/"h1hi"]' })
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
    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
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
      perform_enqueued_jobs_sequentially(delay_seconds: 3, only: WorkflowExecutionStatusJob)
    end

    assert_performed_jobs(6, only: WorkflowExecutionStatusJob)
    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert @workflow_execution.reload.completing?
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
      perform_enqueued_jobs_sequentially(delay_seconds: 2, only: WorkflowExecutionStatusJob)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(3, only: WorkflowExecutionStatusJob)
    @workflow_execution.reload
    assert @workflow_execution.error?
    assert @workflow_execution.http_error_code == 400
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
      perform_enqueued_jobs_sequentially(delay_seconds: 2, only: WorkflowExecutionStatusJob)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_performed_jobs(2, only: WorkflowExecutionStatusJob)
    assert @workflow_execution.reload.completing?
  end

  test 'execution where namespace is removed before status is run' do
    workflow_execution = workflow_executions(:workflow_execution_missing_namespace)

    WorkflowExecutionStatusJob.perform_later(workflow_execution)
    perform_enqueued_jobs_sequentially(delay_seconds: 2, only: WorkflowExecutionStatusJob)

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
    assert workflow_execution.reload.error?
  end

  test 'execution where run_id is missing' do
    workflow_execution = workflow_executions(:workflow_execution_missing_run_id)

    WorkflowExecutionStatusJob.perform_later(workflow_execution)
    perform_enqueued_jobs_sequentially(delay_seconds: 2, only: WorkflowExecutionStatusJob)

    assert_enqueued_jobs(1, only: WorkflowExecutionCleanupJob)
    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
    assert workflow_execution.reload.error?
  end

  test 'canceling workflow should return early' do
    workflow_execution = workflow_executions(:irida_next_example_canceling)

    WorkflowExecutionStatusJob.perform_later(workflow_execution)
    perform_enqueued_jobs(only: WorkflowExecutionStatusJob)

    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
    assert_enqueued_jobs(0)
  end

  test 'canceled workflow should return early' do
    workflow_execution = workflow_executions(:irida_next_example_canceled)

    WorkflowExecutionStatusJob.perform_later(workflow_execution)
    perform_enqueued_jobs(only: WorkflowExecutionStatusJob)

    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
    assert_enqueued_jobs(0)
  end

  test 'min_run_time with running state should delay status check' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 1)
    workflow_execution = workflow_executions(:irida_next_example_running)
    min_run_time = 300 # 5 minutes in seconds

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock_client do
      @stubs.get("/runs/#{workflow_execution.run_id}/status") do |_env|
        [
          200,
          { 'Content-Type': 'application/json' },
          {
            run_id: workflow_execution.run_id,
            state: 'RUNNING'
          }
        ]
      end

      WorkflowExecutionStatusJob.perform_later(workflow_execution, min_run_time)
      perform_enqueued_jobs(only: WorkflowExecutionStatusJob)
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionStatusJob)
    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
  end

  test 'min_run_time with non-running state should proceed normally' do
    mock_client = connection_builder(stubs: @stubs, connection_count: 1)
    min_run_time = 300 # 5 minutes in seconds

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
        WorkflowExecutionStatusJob.perform_later(@workflow_execution, min_run_time)
      end
    end

    assert_enqueued_jobs(1, only: WorkflowExecutionCompletionJob)
    assert_performed_jobs(1, only: WorkflowExecutionStatusJob)
    assert @workflow_execution.reload.completing?
  end

  test 'workflow execution exceeds maximum runtime should queue cancellation job' do
    # Set up pipeline schema to get max_runtime
    @pipeline_schema_file_dir = "#{ActiveStorage::Blob.service.root}/pipelines"
    Irida::Pipelines.new(pipeline_config_file: 'test/config/pipelines/pipelines.json',
                         pipeline_schema_file_dir: @pipeline_schema_file_dir)

    workflow_execution = workflow_executions(:irida_next_example_running)
    job = WorkflowExecutionStatusJob.new

    # Mock state_time_calculation to return a large run time (400 seconds)
    # The max_runtime for iridanextexample version 1.0.3 with 1 sample is 35 seconds
    job.stub :state_time_calculation, 400 do
      job.requeue_or_cancel(workflow_execution)
    end

    assert workflow_execution.reload.canceling?
    assert_enqueued_jobs(1, only: WorkflowExecutionCancelationJob)
  end
end
