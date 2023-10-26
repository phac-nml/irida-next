# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    module V1
      # API Connection GA4GH WES
      # authentication token should be set in credentials/secrets file as ga4gh_wes:oauth_token
      class ApiRequester
        include ApiExceptions

        attr_reader :conn

        # @param conn [Integrations::Ga4ghWesApi::V1::ApiConnection]
        # Usage: ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new(
        #   Integrations::Ga4ghWesApi::V1::ApiConnection.new('http://localhost:7500/').conn )
        def initialize(conn)
          @conn = conn
        end

        private

        def get(endpoint:, params: nil)
          response = @conn.get(endpoint) do |req|
            req.params = params if params.present?
            req.headers['Content-Type'] = 'application/json'
          end
          response.body.deep_symbolize_keys
        rescue Faraday::Error => e
          handle_error e
        end

        def post(endpoint:, params: nil, data: nil)
          response = @conn.post(endpoint) do |req|
            req.params = params if params.present?
            req.headers['Content-Type'] = 'application/json'
            req.body = data.to_json if data.present?
          end
          response.body.deep_symbolize_keys
        rescue Faraday::Error => e
          handle_error e
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
