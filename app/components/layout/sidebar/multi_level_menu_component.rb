# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar multi level menu item component
    class MultiLevelMenuComponent < Component
      attr_reader :title, :icon, :selectable_pages, :current_page

      renders_many :menu_items, ItemComponent

      def initialize(title: nil, icon: nil, selectable_pages: nil, current_page: nil)
        @title = title
        @icon = icon
        @selectable_pages = selectable_pages
        @current_page = current_page
      end
    end
  end
end
