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
      end

      def create_icon
        return unless @icon

        base_options = {}
        base_options[:variant] = :duotone
        base_options[:class] = class_names(
          'size-5',
          'fill-primary-700 text-primary-700': @selected,
          'fill-slate-500 stroke-slate-300': !@selected
        )
        helpers.render_icon(@icon, **base_options)
      end
    end
  end
end
