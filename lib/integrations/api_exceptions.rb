# frozen_string_literal: true

module Integrations
  # Defines exceptions classes for API integrations
  module ApiExceptions
    # Only occurs if the API is unreachable
    ConnectionError = Class.new(StandardError)

    # parent class for API exceptions
    class APIExceptionError < StandardError
      attr_reader :http_error_code

      def initialize(http_error_code)
        super
        @http_error_code = http_error_code
      end
    end

    # HTTP 400
    class BadRequestError < APIExceptionError
      def initialize
        super(400)
      end
    end

    # HTTP 401
    class UnauthorizedError < APIExceptionError
      def initialize
        super(401)
      end
    end

    # HTTP 403
    class ForbiddenError < APIExceptionError
      def initialize
        super(403)
      end
    end

    # HTTP 404
    class NotFoundError < APIExceptionError
      def initialize
        super(404)
      end
    end

    # HTTP 500
    class ApiError < APIExceptionError
      def initialize
        super(500)
      end
    end
  end
end
