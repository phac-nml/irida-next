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
    end
  end
end
