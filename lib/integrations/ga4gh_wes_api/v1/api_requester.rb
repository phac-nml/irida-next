# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    module V1
      # API Connection GA4GH WES
      # authentication token should be set in credentials/secrets file as ga4gh_wes:oauth_token
      class ApiRequester
        include ApiExceptions

        attr_reader :conn

        # Defaults to setting server info from credentials ga4gh_wes:server_url and ga4gh_wes:server_endpoint
        # This can be overriden by setting one of conn: or url:
        #
        # @param conn: [Integrations::Ga4ghWesApi::V1::ApiConnection]
        # @param url: [String]
        # Usage: ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: Faraday.new('http://localhost:7500/'))
        # Usage: ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new(url: 'http://localhost:7500/')
        def initialize(conn: nil, url: nil)
          @conn = if !conn.nil?
                    conn
                  elsif !url.nil?
                    Integrations::Ga4ghWesApi::V1::ApiConnection.new(url).conn
                  else
                    Integrations::Ga4ghWesApi::V1::ApiConnection.new.conn
                  end
        end

        private

        def get(endpoint:, params: nil)
          response = @conn.get(endpoint) do |req|
            req.params = params if params.present?
          end
          response.body&.deep_symbolize_keys
        rescue Faraday::Error => e
          handle_error e
        end

        def post(endpoint:, data: nil)
          response = @conn.post(endpoint, data)
          response.body&.deep_symbolize_keys # return nil if body is nil
        rescue Faraday::Error => e
          handle_error e
        end

        def handle_error(err) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
          Rails.logger.debug do
            output = "DEBUG: Handling error #{err.class.name} for ga4gh_wes_api\n"
            if err.response
              output += "status: #{err.response[:status]}\n" \
                        "headers: #{err.response[:headers]}\n" \
                        "body: #{err.response[:body]}\n" \
                        "urlpath: #{err.response[:request][:url_path]}"
            end
            output
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
          when Faraday::ServerError # 500
            raise ApiError, err.message
          when Faraday::ConnectionFailed # end of file error when server is not responsive
            raise ConnectionError, err.message
          end
        end
      end
    end
  end
end
