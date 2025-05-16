# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component
    class ItemComponent < Component
      attr_reader :url, :label, :selected, :icon

      def initialize(url:, label:, icon: nil, selected: false)
        @url = url
        @label = label
        @icon = icon
        @selected = selected
      end

      def create_icon
        return unless @icon

        base_options = {}
        base_options[:variant] = :duotone unless selected # Keep duotone for non-selected
        base_options[:class] = class_names(
          'size-5',
          'text-primary-50 dark:text-slate-50 stroke-2': selected,
          'text-slate-500 dark:text-slate-400 group-hover:text-slate-900 dark:group-hover:text-slate-50': !selected
        )
        helpers.render_icon(@icon, **base_options)
      end
    end
  end
end
