# frozen_string_literal: true

module Irida
  # Module to encapsulate auth for IRIDA
  module Auth
    # Scopes used for IRIDA
    API_SCOPE = :api
    READ_API_SCOPE = :read_api
    API_SCOPES = [API_SCOPE, READ_API_SCOPE].freeze

    class << self
      def all_available_scopes
        API_SCOPES
      end
    end
  end
end
