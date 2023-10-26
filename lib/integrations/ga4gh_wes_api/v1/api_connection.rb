# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # API Connection GA4GH WES
      # authentication token should be set in credentials/secrets file as ga4gh_wes:oauth_token
      class ApiConnection
        include ApiExceptions

        attr_reader :api_endpoint

        # @param api_server_url [String] API Server url without endpoint path. ex: 'http://localhost:7500/'
        # Usage: ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new(
        #   Integrations::Ga4ghWesApi::V1::ApiConnection.new('http://localhost:7500/') )
        def initialize(api_server_url)
          # Endpoint with path and version
          @api_endpoint = api_server_url + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION
        end

        def get(endpoint:, params: nil)
          response = conn.get(endpoint) do |req|
            req.params = params if params.present?
            req.headers['Content-Type'] = 'application/json'
          end
          response.body.deep_symbolize_keys
        rescue Faraday::Error => e
          handle_error e
        end

        def post(endpoint:, params: nil, data: nil)
          response = conn.post(endpoint) do |req|
            req.params = params if params.present?
            req.headers['Content-Type'] = 'application/json'
            req.body = data.to_json if data.present?
          end
          response.body.deep_symbolize_keys
        rescue Faraday::Error => e
          handle_error e
        end

        private

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

        def handle_error(err) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          Rails.logger.debug do
            "DEBUG: Handling error for ga4gh_wes_api\n" \
              "status: #{err.response[:status]}\n" \
              "headers: #{err.response[:headers]}\n" \
              "body: #{err.response[:body]}\n" \
              "urlpath: #{err.response[:request][:url_path]}"
          end
          case err # These are all the error responses defined by Ga4ghW Wes Api v1
          when Faraday::BadRequestError # 400
            raise BadRequestError, err.message
          when Faraday::UnauthorizedError # 401
            raise UnauthorizedError, err.message
          when Faraday::ForbiddenError # 403
            raise ForbiddenError, err.message
          when Faraday::ResourceNotFound # 404
            raise NotFoundError, err.message
          when Faraday::ClientError # 500
            raise ApiError, err.message
          end
        end
      end
    end
  end
end
