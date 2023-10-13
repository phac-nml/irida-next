# frozen_string_literal: true

module GA4GHWESAPI
  module V110
    class Client
      API_ENDPOINT = 'https://somewhere'

      def initialize(maybe_token = nil)
        @token = maybe_token
      end
    end
  end
end
