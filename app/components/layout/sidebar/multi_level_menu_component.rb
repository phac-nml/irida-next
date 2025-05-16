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

      def icon_classes(selected)
        class_names(
          'size-5',
          {
            'text-primary-50 dark:text-slate-50 stroke-2': selected,
            'text-slate-500 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-slate-50': !selected
          }
        )
      end

      def render_icon(icon, selected)
        helpers.render_icon(icon, class: icon_classes(selected), variant: (selected ? nil : :duotone))
      end

      def create_icon
        return unless @icon

        render_icon(@icon, @selected)
      end
    end
  end
end
