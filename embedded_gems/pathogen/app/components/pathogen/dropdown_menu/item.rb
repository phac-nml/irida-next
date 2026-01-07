# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Standard menu item.
    class Item < Pathogen::Component
      def initialize(label:, href: nil, disabled: false, destructive: false, **system_arguments)
        @label = label
        @href = href
        @disabled = disabled
        @destructive = destructive
        @system_arguments = system_arguments
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def call
        tag_name = @href.present? && !@disabled ? :a : :button

        data = (@system_arguments[:data] || {}).dup
        existing_action = data[:action] || data['action']
        data['pathogen--dropdown-menu-target'] = 'item'
        data[:action] = class_names(existing_action, 'click->pathogen--dropdown-menu#activate')

        base_classes = class_names(
          'w-full flex items-center gap-2 px-3 py-2 text-sm text-left',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600',
          'rounded-md',
          'hover:bg-slate-100 dark:hover:bg-slate-800',
          'disabled:opacity-60 disabled:cursor-not-allowed',
          'text-red-600 dark:text-red-300' => @destructive
        )

        system_arguments = {
          tag: tag_name,
          type: (tag_name == :button ? :button : nil),
          href: (tag_name == :a ? @href : nil),
          disabled: (tag_name == :button ? @disabled : nil),
          'aria-disabled': (@disabled ? 'true' : nil),
          role: 'menuitem',
          tabindex: -1,
          data: data,
          class: class_names(base_classes, @system_arguments[:class])
        }.compact

        content_tag(tag_name, @label, **@system_arguments.except(:class), **system_arguments)
      end

      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
