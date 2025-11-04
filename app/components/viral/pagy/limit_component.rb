# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:)
        @pagy = pagy
        @item = item
      end

      private

      def current_url_without_params
        current_uri = URI.parse(request.original_url)

        current_uri.query = '' if current_uri.query

        current_uri.to_s
      end

      def current_url_query_params_without_limit
        current_uri = URI.parse(request.original_url)
        query_params = {}

        if current_uri.query
          query_params = URI.decode_www_form(current_uri.query).to_h
          query_params.delete('limit')
        end

        query_params
      end
    end
  end
end
