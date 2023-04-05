# frozen_string_literal: true

module Layout
  module Sidebar
    class ItemComponent < Component
      def initialize(url:, label:, icon: nil, badge: nil, selected: false, link_arguments: {}, **system_arguments)
        @url = url
        @label = label
        @icon = icon
        @badge = badge
        @selected = selected
        @link_arguments = link_arguments
        @system_arguments = system_arguments
      end

      def system_arguments
        @system_arguments.tap do |opts|
          opts[:tag] = 'li'
          opts[:classes] = class_names(
            @system_arguments[:classes],
            'Viral-Sidebar__ListItem'
          )
        end
      end

      def link_arguments
        @link_arguments.tap do |opts|
          opts[:class] = class_names(
            @link_arguments[:classes],
            link_classes
          )
          opts[:tabindex] = '0'
          opts[:target] = '_blank' if @external
        end
      end

      def link_classes
        class_names(
          'Viral-Sidebar__Item',
          'Viral-Sidebar__Item--selected': @selected,
          'Viral-Sidebar--subNavigationActive': @selected,
          'Viral-Sidebar__Item--disabled': @disabled
        )
      end
    end
  end
end
