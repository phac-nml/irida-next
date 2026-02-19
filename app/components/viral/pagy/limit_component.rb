# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:)
        @pagy = pagy
        @item = item
      end
    end
  end
end
