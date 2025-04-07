# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class ItemComponent < Component
      attr_reader :url, :label, :icon_name, :selected

      def initialize(url:, label:, icon: nil, selected: false)
        @url = url
        @label = label
        @icon_name = icon
        @selected = selected
      end

      def item_icon
        icon @icon_name, class: 'size-4', style: 'width: 27px;'
      end
    end
  end
end
