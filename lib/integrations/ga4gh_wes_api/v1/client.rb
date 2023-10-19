# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    API_SERVER_ENDPOINT_PATH = 'ga4gh/wes/'
    module V1
      API_SERVER_ENDPOINT_VERSION = 'v1/'
      # API Integration with GA4GH WES
      class Client
        include ApiExceptions
        include HttpStatusCodes

        # TODO: put this server url in a secrets file
        API_SERVER_URL = 'http://localhost:7500/'
        # Endpoint with path and version
        API_ENDPOINT = API_SERVER_URL + Ga4ghWesApi::API_SERVER_ENDPOINT_PATH + V1::API_SERVER_ENDPOINT_VERSION

        # attr_reader :oauth_token

        def initialize(oauth_token = nil)
          # @oauth_token = oauth_token
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

        def run(run_id)
          request(
            http_method: :get,
            endpoint: "runs/#{run_id}"
          )
        end

        def run_workflow(workflow_type:, workflow_type_version:, workflow_url:, workflow_params:)
          job_params = { workflow_type:, workflow_type_version:, workflow_url:, workflow_params: }

          request(
            http_method: :post,
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

        def client
          @client ||= Faraday.new(API_ENDPOINT) do |client|
            client.request :url_encoded
            client.adapter Faraday.default_adapter
            # client.headers['Authorization'] = "token #{oauth_token}" if oauth_token.present?
          end
        end

        def request(http_method:, endpoint:, params: {})
          response = client.public_send(http_method, endpoint, params)
          parsed_response = JSON.parse(response.body)

          return parsed_response if response_successful?(response)

          raise error_class(response), "Code: #{response.status}, response: #{response.body}"
        end

        def response_successful?(response)
          response.status == HTTP_OK_CODE
        end

        def error_class(response)
          case response.status
          when HTTP_BAD_REQUEST_CODE
            BadRequestError
          when HTTP_UNAUTHORIZED_CODE
            UnauthorizedError
          when HTTP_FORBIDDEN_CODE
            ForbiddenError
          when HTTP_NOT_FOUND_CODE
            NotFoundError
          when HTTP_UNPROCESSABLE_ENTITY_CODE
            UnprocessableEntityError
          else
            # TODO: example code, to remove
            # return SpecialError if some_special_condition?
            ApiError
          end
        end

        # TODO: example code, to remove
        # def some_special_condition?
        #   response.body.match?('some state')
        # end
      end
    end
  end
end
