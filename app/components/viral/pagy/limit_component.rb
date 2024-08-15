# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:)
        @pagy = pagy
        @item = item
      end

      def link_classes
        'flex items-center h-8 px-3'
      end
    end
  end
end
