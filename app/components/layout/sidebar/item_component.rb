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

      def create_icon
        return unless @icon

        base_options = {}
        base_options[:variant] = :duotone
        base_options[:class] = class_names(
          'size-5',
          'fill-primary-700 text-primary-700': selected,
          'fill-slate-500 stroke-slate-300': !selected
        )
        helpers.render_icon(@icon, **base_options)
      end
    end
  end
end
