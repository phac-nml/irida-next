# frozen_string_literal: true

require 'minitest/mock'

module ActiveJobTestHelpers
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

  # Mutable stubs, allowing adding/changing stubbed endpoints mid test
  def faraday_test_adapter_stubs
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/service-info') do |_env|
        [
          200,
          { 'Content-Type': 'text/plain' },
          'stubbed text'
        ]
      end
    end
  end

  # test adapter for Faraday using mutable stubs
  def connection_builder(stubs:, connection_count:)
    test_conn = Faraday.new do |builder|
      builder.adapter :test, stubs
    end

    # Client to mock api connections
    mock_client = Minitest::Mock.new
    while connection_count >= 1
      mock_client.expect(:conn, test_conn)
      connection_count -= 1
    end

    mock_client
  end
end
