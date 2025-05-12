# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar multi level menu item component
    class MultiLevelMenuComponent < Component
      attr_reader :title, :selectable_pages, :current_page

      renders_many :menu_items, ItemComponent

      def initialize(title: nil, icon: nil, selectable_pages: [], current_page: nil)
        @title = title
        @icon = icon
        @selectable_pages = selectable_pages
        @current_page = current_page
        @selected = selectable_pages.include?(current_page) # Determine if the main menu item is selected
      end

      def create_icon
        return unless @icon

        base_options = {}
        # Apply duotone only when not selected for a more subtle look
        base_options[:variant] = :duotone unless @selected
        base_options[:class] = class_names(
          'size-5',
          {
            # Selected state: white or slate-50 icon for modern dark look
            'text-white dark:text-slate-50': @selected,
            # Non-selected state: slate text, changes on group hover (group class to be added in HTML)
            'text-slate-500 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-slate-50': !@selected
          }
        )
        helpers.render_icon(@icon, **base_options)
      end
    end
  end
end
