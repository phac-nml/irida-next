# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    # API Integration with GA4GH WES
    class Client
      include ApiExceptions
      include HttpStatusCodes

      # TODO: put these endpoints/consts in a secrets file
      API_ENDPOINT = 'http://localhost:7500/ga4gh/wes/v1/'

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

      # TODO: dummy method to be removed
      def some_req_w_arg(my_arg)
        request(
          http_method: :get,
          endpoint: "some/#{my_arg}/path"
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
