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

    # Client to mock api connections
    @mock_client = Minitest::Mock.new
    @mock_client.expect(:conn, @test_conn)
  end

  def teardown
    # reset connections after each test to clear cache
    Faraday.default_connection = nil
  end

  test 'proof of concept test' do
    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, @mock_client do
      @stubs.get('/asdf') { |_env| [200, {}, 'qwerty'] }

      @stubs.get('/boom') do
        raise Faraday::ConnectionFailed
      end

      perform_enqueued_jobs do
        WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
      end
    end
  end
end
