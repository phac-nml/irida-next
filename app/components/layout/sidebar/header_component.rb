# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar header component to indicate the current page
    class HeaderComponent < Component
      attr_reader :label, :item

      def initialize(label:, item: nil)
        @label = label
        @item = item
      end
    end
  end
end
