# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar header component to indicate the current page
    class HeaderComponent < Component
      def initialize(label:, icon:, url:)
        @label = label
        @icon = icon
        @url = url
      end
    end
  end
end
