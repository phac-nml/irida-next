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

        # @param api_server_url [String] Optional: API Server url without endpoint path.
        #   Path is then generated by REST versioning standard. ex: 'http://localhost:7500/'
        # Default: server url with endpoint is set from credentials file as ga4gh_wes:server_url_endpoint
        def initialize(api_server_url = nil)
          @api_endpoint = if api_server_url.nil? && Rails.application.credentials.ga4gh_wes.nil?
                            "http://www.example.com/#{Ga4ghWesApi::API_SERVER_ENDPOINT_PATH}#{V1::API_SERVER_ENDPOINT_VERSION}"
                          elsif api_server_url.nil? && Rails.application.credentials.ga4gh_wes.present?
                            Rails.application.credentials.dig(:ga4gh_wes, :server_url_endpoint)
                          else
                            # Endpoint with path and version
                            api_server_url + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION
                          end
        end

        def conn
          headers = { 'Content-Type': 'application/json' }
          extra_headers = Rails.application.credentials.dig(:ga4gh_wes, :headers)
          headers = headers.merge(extra_headers) unless extra_headers.nil?

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
