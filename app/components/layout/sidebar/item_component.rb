# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class ItemComponent < Component
      def initialize(url:, label:, icon: nil)
        @url = url
        @label = label
        @icon = icon
      end
    end
  end
end
