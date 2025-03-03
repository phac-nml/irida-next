# frozen_string_literal: true

require 'minitest/mock'

module ActiveJobTestHelpers
  # Jobs that are retried must be run one at a time with a short delay to prevent stack errors
  # Allows use of only/except to exit early like perform_enqueued_jobs does
  def perform_enqueued_jobs_sequentially(delay_seconds: 1, only: nil, except: nil) # rubocop:disable Metrics/AbcSize
    class_filter = lambda { |job_class|
      (only.nil? || job_class == only.name) &&
        (except.nil? || job_class != except.name)
    }

    while enqueued_jobs.count >= 1 && class_filter.call(enqueued_jobs.first['job_class'])
      perform_enqueued_jobs(
        only: ->(job) { job['job_id'] == enqueued_jobs.first['job_id'] },
        queue: :waitable_queue
      )
      sleep(delay_seconds)
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
