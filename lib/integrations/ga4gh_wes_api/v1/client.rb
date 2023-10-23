# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # API Integration with GA4GH WES
      class Client
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

        def runs
          get(
            endpoint: 'runs'
          )
        end

        def run(run_id)
          get(
            endpoint: "runs/#{run_id}"
          )
        end

        def run_workflow(
          workflow_type: nil,
          workflow_type_version: nil,
          workflow_url: nil,
          workflow_params: nil
        )
          job_params = {}
          job_params['workflow_type'] = workflow_type if workflow_type.present?
          job_params['workflow_type_version'] = workflow_type_version if workflow_type_version.present?
          job_params['workflow_url'] = workflow_url if workflow_url.present?
          job_params['workflow_params'] = workflow_params if workflow_params.present?

          post(
            endpoint: 'runs',
            params: job_params
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
        def handle_error(err)
          puts "status: #{err.response[:status]}"
          puts "headers: #{err.response[:headers]}"
          puts "body: #{err.response[:body]}"
          puts "urlpath: #{err.response[:request][:url_path]}"
          case err
          when Faraday::ClientError # 4XX
            puts '4XX error'
            raise
          when Faraday::ServerError # 5XX
            puts '5XX error'
            raise
          end
        end
      end
    end
  end
end
