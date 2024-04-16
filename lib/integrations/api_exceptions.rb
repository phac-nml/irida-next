# frozen_string_literal: true

module Integrations
  module ApiExceptions
    APIExceptionError = Class.new(StandardError)
    BadRequestError = Class.new(APIExceptionError)
    UnauthorizedError = Class.new(APIExceptionError)
    ForbiddenError = Class.new(APIExceptionError)
    NotFoundError = Class.new(APIExceptionError)
    ApiError = Class.new(APIExceptionError)
    ServerError = Class.new(APIExceptionError)
  end
end
