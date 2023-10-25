# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # API Integration with GA4GH WES
      # TODO: should this class be shortened somehow to be in line with rubocop?
      class Client # rubocop:disable Metrics/ClassLength
        include ApiExceptions

        attr_reader :api_endpoint, :oauth_token

        # @param api_server_url [String] API Server url without endpoint path. ex: 'http://localhost:7500/'
        # @param oauth_token [String] OAuth2 bearer token
        def initialize(api_server_url, oauth_token: nil)
          # Endpoint with path and version
          @api_endpoint = api_server_url + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION
          @oauth_token = oauth_token
        end

        def service_info
          get(
            endpoint: 'service-info'
          )
        end

        # Arguments are defined here:
        # https://ga4gh.github.io/workflow-execution-service-schemas/docs/#tag/Workflow-Runs/operation/ListRuns
        # @param page_size [Integer <int64>] Optional
        # @param page_token [String] Optional
        def list_runs(**params)
          get(
            endpoint: 'runs',
            params:
          )
        end

        # Requires some of the following arguments as defined here:
        # https://ga4gh.github.io/workflow-execution-service-schemas/docs/#tag/Workflow-Runs/operation/RunWorkflow
        # @param workflow_params [String]
        # @param workflow_type [String]
        # @param workflow_type_version [String]
        # @param tags [String]
        # @param workflow_engine [String]
        # @param workflow_engine_version [String]
        # @param workflow_engine_parameters [String]
        # @param workflow_url [String]
        # @param workflow_attachment [Array of strings <binary>] TODO: Test how this works
        def run_workflow(**params)
          post(
            endpoint: 'runs',
            params:
          )
        end

        # @param run_id [String] Required
        def get_run_log(run_id)
          get(
            endpoint: "runs/#{run_id}"
          )
        end

        # @param run_id [String] Required
        def get_run_status(run_id)
          get(
            endpoint: "runs/#{run_id}/status"
          )
        end

        # @param run_id [String] Required
        # @param page_size [Integer <int64>] Optional
        # @param page_token [String] Optional
        def list_tasks(run_id, **params)
          get(
            endpoint: "runs/#{run_id}/tasks", # TODO: can't get any tasks paths, 404
            params:
          )
        end

        # @param run_id [String] Required
        # @param task_id [String] Required
        def get_task(run_id, task_id)
          get(
            endpoint: "runs/#{run_id}/tasks/#{task_id}"
          )
        end

        # @param run_id [String] Required
        def cancel_run(run_id)
          post(
            endpoint: "runs/#{run_id}/cancel"
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
          @conn ||= Faraday.new(@api_endpoint) do |f|
            f.request :authorization, 'Bearer', -> { @oauth_token }
            f.request :json # encode req bodies as JSON
            f.request :url_encoded
            f.response :logger # logs request and responses
            f.response :json # decode response bodies as JSON
            f.response :raise_error, include_request: true
            f.adapter :net_http # Use the Net::HTTP adapter
          end
        end

        def post(endpoint:, params: nil, data: nil)
          response = conn.post(endpoint) do |req|
            req.params = params if params.present?
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
