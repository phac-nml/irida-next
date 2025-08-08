# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:)
        @pagy = pagy
        @item = item
      end

      def current_url_without_limit
        current_uri = URI.parse(request.original_url)

        if current_uri.query
          query_params = URI.decode_www_form(current_uri.query).to_h
          query_params.delete('limit')
          new_query_string = URI.encode_www_form(query_params)
          current_uri.query = new_query_string
        end

        current_uri.to_s
      end
    end
  end
end
