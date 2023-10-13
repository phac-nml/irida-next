# frozen_string_literal: true

module Ga4ghWesApi
  # API Integration with GA4GH WES
  class Client
    API_ENDPOINT = 'http://localhost:7500/ga4gh/wes/v1/'

    attr_reader :oauth_token

    def initialize(oauth_token = nil)
      @oauth_token = oauth_token
    end

    def service_info
      request(
        http_method: :get,
        endpoint: 'service-info'
      )
    end

    def runs
      request(
        http_method: :get,
        endpoint: 'runs'
      )
    end

    private

    def client
      @_client ||= Faraday.new(API_ENDPOINT) do |client|
        client.request :url_encoded
        # client.adapter Faraday.default_adapter
        client.headers['Authorization'] = "token #{oauth_token}" if oauth_token.present?
      end
    end

    def request(http_method:, endpoint:, params: {})
      response = client.public_send(http_method, endpoint, params)
      Oj.load(response.body)
    end
  end
end
