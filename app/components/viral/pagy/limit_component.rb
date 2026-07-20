# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      LIMITS = [10, 20, 50, 100].freeze

      def initialize(pagy, item:, params: {})
        @pagy = pagy
        @item = item
        @params = params
      end

      # GET forms replace the action query string with submitted fields, so every
      # query param that must survive a page-size change has to be a form field.
      def preserved_hidden_fields
        flatten_params(preserved_query_params)
      end

      private

      def preserved_query_params
        request.query_parameters
               .to_h
               .deep_stringify_keys
               .deep_merge(@params.deep_stringify_keys)
               .except('limit', 'page')
      end

      def flatten_params(value, prefix = nil)
        case value
        when Hash
          value.flat_map { |key, nested| flatten_params(nested, param_name(prefix, key)) }
        when Array
          value.flat_map { |nested| flatten_params(nested, "#{prefix}[]") }
        else
          [[prefix, value]]
        end
      end

      def param_name(prefix, key)
        prefix ? "#{prefix}[#{key}]" : key.to_s
      end
    end
  end
end
