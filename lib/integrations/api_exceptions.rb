# frozen_string_literal: true

module Integrations
  # Defines exceptions classes for API integrations
  module ApiExceptions
    # Only occurs if the API is unreachable
    ConnectionError = Class.new(StandardError)

    # parent class for API exceptions
    class APIExceptionError < StandardError
      attr_reader :http_error_code

      def initialize(msg, http_error_code)
        @http_error_code = http_error_code
        super(msg)
      end
    end

    # HTTP 400
    class BadRequestError < APIExceptionError
      def initialize(msg)
        super(msg, 400)
      end
    end

    # HTTP 401
    class UnauthorizedError < APIExceptionError
      def initialize(msg)
        super(msg, 401)
      end
    end

    # HTTP 403
    class ForbiddenError < APIExceptionError
      def initialize(msg)
        super(msg, 403)
      end
    end

    # HTTP 404
    class NotFoundError < APIExceptionError
      def initialize(msg)
        super(msg, 404)
      end
    end

    # HTTP 500
    class ApiError < APIExceptionError
      def initialize(msg)
        super(msg, 500)
      end
    end
  end
end
