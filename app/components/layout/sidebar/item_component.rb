# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class ItemComponent < Component
      attr_reader :url, :label, :icon, :current_page

      def initialize(url:, label:, icon: nil, current_page: nil)
        @url = url
        @label = label
        @icon = icon
        @current_page = current_page
      end
    end
  end
end
