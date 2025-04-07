# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar multi level menu item component
    class MultiLevelMenuComponent < Component
      attr_reader :title, :selectable_pages, :current_page

      renders_many :menu_items, ItemComponent

      def initialize(title: nil, icon: nil, selectable_pages: [], current_page: nil)
        @title = title
        @icon_name = icon
        @selectable_pages = selectable_pages
        @current_page = current_page
      end

      def menu_icon
        return unless @icon_name

        icon @icon_name, class: 'size-4', style: 'width: 27px;'
      end
    end
  end
end
