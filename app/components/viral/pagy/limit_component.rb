# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:)
        @pagy = pagy
        @item = item
      end

      def current_url_with_limit(limit)
        current_url = request.original_url
        if current_url.include? '?'
          split_url = current_url.split('?')
          base_url = split_url[0]
          get_params = split_url[1].split('&')
          reconstructed_params = "?limit=#{limit}"
          get_params.each do |param|
            reconstructed_params << "&#{param}" unless param.include? 'limit='
          end
          "#{base_url}#{reconstructed_params}"
        else
          "#{current_url}?limit=#{limit}"
        end
      end
    end
  end
end
