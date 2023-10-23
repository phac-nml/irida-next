# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # API Integration with GA4GH WES

      # TODO: should the class be shortened/split up somehow?
      class Client # rubocop:disable Metrics/ClassLength
        include ApiExceptions

        # TODO: put this server url in a secrets file
        API_SERVER_URL = 'http://localhost:7500/'
        # Endpoint with path and version
        API_ENDPOINT = API_SERVER_URL + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION

        # attr_reader :oauth_token

        def initialize(oauth_token = nil)
          # @oauth_token = oauth_token
        end

        def service_info
          get(
            endpoint: 'service-info'
          )
        end

        def runs(
          page_size: nil,
          page_token: nil
        )
          params = {}
          params['page_size'] = page_size if page_size.present?
          params['page_token'] = page_token if page_token.present?
          get(
            endpoint: 'runs',
            params:
          )
        end

        def run(run_id)
          get(
            endpoint: "runs/#{run_id}"
          )
        end

        def run_workflow( # rubocop:disable Metrics
          workflow_params: nil,
          workflow_type: nil,
          workflow_type_version: nil,
          tags: nil,
          workflow_engine: nil,
          workflow_engine_version: nil,
          workflow_engine_parameters: nil,
          workflow_url: nil,
          workflow_attachment: nil # TODO: this is an 'Array of strings <binary>', probably needs special handling
        )
          # TODO: is there a better way to do this in ruby?
          params = {}
          params['workflow_params'] = workflow_params if workflow_params.present?
          params['workflow_type'] = workflow_type if workflow_type.present?
          params['workflow_type_version'] = workflow_type_version if workflow_type_version.present?
          params['tags'] = tags if tags.present?
          params['workflow_engine'] = workflow_engine if workflow_engine.present?
          params['workflow_engine_version'] = workflow_engine_version if workflow_engine_version.present?
          params['workflow_engine_parameters'] = workflow_engine_parameters if workflow_engine_parameters.present?
          params['workflow_url'] = workflow_url if workflow_url.present?
          params['workflow_attachment'] = workflow_attachment if workflow_attachment.present?

          post(
            endpoint: 'runs',
            params:
          )
        end

        # Runs a md5 hash check. The method is used for testing connection with server api
        def run_test_nextflow_md5_job
          run_workflow(
            workflow_type: 'NEXTFLOW',
            workflow_type_version: '21.04.0',
            workflow_url: 'https://github.com/jb-adams/md5-nf',
            workflow_params: '{"file_int": 3}'
          )
        end

        private

        def conn
          @conn ||= Faraday.new(API_ENDPOINT) do |f|
            # f.request :authorization, 'Bearer', -> { MyAuthStorage.get_auth_token }
            f.request :json # encode req bodies as JSON
            f.request :url_encoded
            f.response :logger # logs request and responses
            f.response :json # decode response bodies as JSON
            f.response :raise_error, include_request: true
            f.adapter :net_http # Use the Net::HTTP adapter
          end
        end

        def post(endpoint:, params:, data: nil)
          response = conn.post(endpoint) do |req|
            req.params = params
            req.headers['Content-Type'] = 'application/json'
            req.body = data.to_json if data.present?
          end
          response.body
        rescue Faraday::Error => e
          handle_error e
        end

        def get(endpoint:, params: nil)
          response = conn.get(endpoint) do |req|
            req.params = params if params.present?
            req.headers['Content-Type'] = 'application/json'
          end
          response.body
        rescue Faraday::Error => e
          handle_error e
        end

        # TODO, replace the 'puts' with proper error handling
        def handle_error(err) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          Rails.logger.debug do
            "DEBUG: Handling error for ga4gh_wes_api\n" \
              "status: #{err.response[:status]}\n" \
              "headers: #{err.response[:headers]}\n" \
              "body: #{err.response[:body]}\n" \
              "urlpath: #{err.response[:request][:url_path]}"
          end
          case err
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
