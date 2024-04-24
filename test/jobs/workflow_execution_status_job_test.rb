# frozen_string_literal: true

require 'minitest/mock'
require 'test_helper'

class WorkflowExecutionStatusJobTest < ActiveJob::TestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_submitted)

    # Mutable stubs, allowing adding/changing stubbed endpoints mid test
    @stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/service-info') do |_env|
        [
          200,
          { 'Content-Type': 'text/plain' },
          'stubbed text'
        ]
      end
    end

    # test adapter for Faraday with above stubs
    @test_conn = Faraday.new do |builder|
      builder.adapter :test, @stubs
    end
  end

  # the mock client needs an `expect` for each connection
  def connections_to_expect(connection_count)
    # Client to mock api connections
    @mock_client = Minitest::Mock.new
    while connection_count >= 1
      @mock_client.expect(:conn, @test_conn)
      connection_count -= 1
    end
  end

  # jobs that are retried must be run one at a time to prevent stack errors
  # This functions the same as `perform_enqueued_jobs(only: MyJob)` but one at a time
  def perform_enqueued_jobs_one_at_a_time(only_class:)
    while enqueued_jobs.count >= 1 && enqueued_jobs.first['job_class'] == only_class.name
      # run a single queued job
      currently_queued_job = enqueued_jobs.first
      perform_enqueued_jobs(
        only: lambda { |job|
          job['job_id'] == currently_queued_job['job_id'] && \
          job['job_class'] == only_class.name
        }
      )
    end
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'successful job execution' do
    connections_to_expect(1)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, @mock_client do
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
    connections_to_expect(6)

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, @mock_client do
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
