# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class MultiLevelMenuComponent < Component
      attr_reader :title

      renders_many :menu_items, ItemComponent

      def initialize(title: nil)
        @title = title
      end
    end
  end
end
