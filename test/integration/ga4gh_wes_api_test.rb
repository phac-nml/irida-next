# frozen_string_literal: true

require 'faraday'
require 'json'
require 'test_helper'

class ClientTest < ActionDispatch::IntegrationTest
  # faraday test adapter for stubs
  def client(stubs)
    conn = Faraday.new do |builder|
      builder.adapter :test, stubs
    end
    # conn replaces Integrations::Ga4ghWesApi::V1::ApiConnection.new('example.com').conn
    Integrations::Ga4ghWesApi::V1::Client.new(conn:)
  end

  def test_get_run_log_id
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/123') do |env|
      assert_equal '/runs/123', env.url.path
      [
        200,
        { 'Content-Type': 'application/javascript' },
        { origin: '127.0.0.1' }
      ]
    end

    cli = client(stubs)
    exp = { origin: '127.0.0.1' }
    assert_equal exp, cli.get_run_log('123')

    stubs.verify_stubbed_calls
  end
end
