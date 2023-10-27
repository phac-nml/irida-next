# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      # REST API spec for versioning
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # Creates a Faraday connection to Ga4gh WES API
      #
      # Additional headers set in credentials file as ga4gh_wes:headers as a Hash
      # Authorization bearer token set in credentials file as ga4gh_wes:oauth_token
      class ApiConnection
        include ApiExceptions

        attr_reader :api_endpoint

        # @param api_server_url [String] API Server url without endpoint path. ex: 'http://localhost:7500/'
        # @param endpoint_override [String] Optional, overrides default REST API spec versioning
        def initialize(api_server_url, endpoint_override = nil)
          # Endpoint with path and version
          @api_endpoint = if endpoint_override.nil?
                            api_server_url + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION
                          else
                            api_server_url + endpoint_override
                          end
        end

        def conn
          headers = { 'Content-Type': 'application/json' }
          headers = headers.merge(Rails.application.credentials.dig(:ga4gh_wes, :headers))
          Faraday.new(
            url: @api_endpoint,
            headers:
          ) do |f|
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
