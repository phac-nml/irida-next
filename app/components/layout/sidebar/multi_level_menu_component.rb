# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar multi level menu item component
    class MultiLevelMenuComponent < Component
      attr_reader :title, :icon

      renders_many :menu_items, ItemComponent

      def initialize(title: nil, icon: nil)
        @title = title
        @icon = icon
      end
    end
  end
end
