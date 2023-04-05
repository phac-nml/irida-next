# frozen_string_literal: true

module Layout
  module Sidebar
    class HeaderComponent < Component
      def initialize(label:, icon:, url:)
        @label = label
        @icon = icon
        @url = url
      end
    end
  end
end
