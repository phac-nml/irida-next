# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # Creates a Faraday connection to Ga4gh WES API
      # authentication token should be set in credentials/secrets file as ga4gh_wes:oauth_token
      class ApiConnection
        include ApiExceptions

        attr_reader :api_endpoint

        # @param api_server_url [String] API Server url without endpoint path. ex: 'http://localhost:7500/'
        def initialize(api_server_url)
          # Endpoint with path and version
          @api_endpoint = api_server_url + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION
        end

        def conn
          Faraday.new(@api_endpoint) do |f|
            # proc so auth is evaluated on each request
            f.request :authorization, 'Bearer', -> { Rails.application.credentials.dig(:ga4gh_wes, :oauth_token) }
            f.request :json # encode req bodies as JSON
            f.request :url_encoded
            f.response :logger # logs request and responses
            f.response :json # decode response bodies as JSON
            f.response :raise_error, include_request: true
            f.adapter :net_http # Use the Net::HTTP adapter
          end
        end
      end
    end
  end
end
