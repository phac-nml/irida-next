# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Checkbox menu item for multi-select.
    class CheckboxItem < Pathogen::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, name:, value:, checked: false, disabled: false, destructive: false, **system_arguments)
        # rubocop:enable Metrics/ParameterLists
        @label = label
        @name = name
        @value = value
        @checked = checked
        @disabled = disabled
        @destructive = destructive
        @system_arguments = system_arguments
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def call
        button_classes = class_names(
          'w-full flex items-center gap-2 px-3 py-2 text-sm text-left rounded-md',
          'hover:bg-slate-100 dark:hover:bg-slate-800',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600',
          'disabled:opacity-60 disabled:cursor-not-allowed',
          'text-red-600 dark:text-red-300' => @destructive
        )

        input_id = self.class.generate_id(base_name: 'dropdown-menu-checkbox')

        wrapper = ActiveSupport::SafeBuffer.new

        wrapper << tag.input(
          type: 'checkbox',
          id: input_id,
          name: @name,
          value: @value,
          checked: @checked,
          class: 'hidden',
          tabindex: -1,
          'aria-hidden': 'true',
          data: {
            'pathogen--dropdown-menu-target': 'input',
            name: @name,
            value: @value
          }
        )

        data = (@system_arguments[:data] || {}).dup
        existing_action = data[:action] || data['action']
        data['pathogen--dropdown-menu-target'] = 'item'
        data[:name] = @name
        data[:value] = @value
        data[:action] = class_names(existing_action, 'click->pathogen--dropdown-menu#toggleCheckbox')

        wrapper << content_tag(
          :button,
          type: :button,
          role: 'menuitemcheckbox',
          tabindex: -1,
          disabled: @disabled,
          'aria-checked': @checked.to_s,
          'aria-disabled': (@disabled ? 'true' : nil),
          data: data,
          class: class_names(button_classes, @system_arguments[:class])
        ) do
          checkbox_ui = content_tag(:span, '', class: class_names(
            'h-4 w-4 inline-flex items-center justify-center rounded border',
            'border-slate-300 dark:border-slate-600',
            'bg-primary-700 border-primary-700 text-white' => @checked
          ))

          checkbox_ui + content_tag(:span, @label, class: 'flex-1')
        end

        wrapper
      end

      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
