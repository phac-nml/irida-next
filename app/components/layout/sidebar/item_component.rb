# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class ItemComponent < Component
      attr_reader :url, :label, :selected

      def initialize(url:, label:, icon: nil, selected: false)
        @url = url
        @label = label
        @icon = icon
        @selected = selected
      end
    end
  end
end
