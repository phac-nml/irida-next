# frozen_string_literal: true

require 'minitest/mock'

module FaradayTestHelpers
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
