# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # One-level submenu entry.
    #
    # Renders a submenu trigger item plus its nested menu.
    class Submenu < Pathogen::Component # rubocop:disable Metrics/ClassLength
      attr_reader :menu_id, :trigger_id, :entries

      def initialize(parent_menu_id:, label:, disabled: false, destructive: false, **system_arguments)
        @parent_menu_id = parent_menu_id
        @label = label
        @disabled = disabled
        @destructive = destructive
        @system_arguments = system_arguments

        @id = self.class.generate_id(base_name: 'dropdown-submenu')
        @trigger_id = "#{@id}-trigger"
        @menu_id = "#{@id}-menu"

        @entries = []
      end

      def with_item(label:, href: nil, disabled: false, destructive: false, **system_arguments)
        @entries << Pathogen::DropdownMenu::Item.new(
          label: label,
          href: href,
          disabled: disabled,
          destructive: destructive,
          **system_arguments
        )
      end

      def with_checkbox_item(label:, name:, value:, **system_arguments)
        @entries << Pathogen::DropdownMenu::CheckboxItem.new(
          label: label,
          name: name,
          value: value,
          **system_arguments
        )
      end

      def with_radio_item(label:, name:, value:, **system_arguments)
        @entries << Pathogen::DropdownMenu::RadioItem.new(
          label: label,
          name: name,
          value: value,
          **system_arguments
        )
      end

      def with_label(text:, **system_arguments)
        @entries << Pathogen::DropdownMenu::Label.new(text: text, **system_arguments)
      end

      def with_separator(**system_arguments)
        @entries << Pathogen::DropdownMenu::Separator.new(**system_arguments)
      end

      def before_render
        raise ArgumentError, 'submenu must have at least one entry' if @entries.empty?
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def call
        trigger_classes = class_names(
          'w-full flex items-center gap-2 px-3 py-2 text-sm text-left rounded-md',
          'hover:bg-slate-100 dark:hover:bg-slate-800',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600',
          'disabled:opacity-60 disabled:cursor-not-allowed',
          'text-red-600 dark:text-red-300' => @destructive
        )

        submenu_actions = [
          'mouseenter->pathogen--dropdown-menu#cancelScheduledSubmenuClose',
          'mouseleave->pathogen--dropdown-menu#closeSubmenuOnLeave'
        ].join(' ')

        submenu_classes = [
          'min-w-[12rem] z-50 rounded-lg border border-slate-200 bg-white shadow-lg',
          'dark:bg-slate-900 dark:border-slate-700',
          'outline-none'
        ].join(' ')

        data = (@system_arguments[:data] || {}).dup
        existing_action = data[:action] || data['action']
        data['pathogen--dropdown-menu-target'] = 'item'
        data[:submenu_trigger] = 'true'
        data[:submenu_menu_id] = @menu_id
        data[:action] = class_names(
          existing_action,
          'click->pathogen--dropdown-menu#toggleSubmenu',
          'mouseenter->pathogen--dropdown-menu#openSubmenuOnHover',
          'mouseleave->pathogen--dropdown-menu#scheduleCloseSubmenu'
        )

        trigger = content_tag(
          :button,
          type: :button,
          id: @trigger_id,
          role: 'menuitem',
          tabindex: -1,
          disabled: @disabled,
          'aria-haspopup': 'menu',
          'aria-expanded': 'false',
          'aria-controls': @menu_id,
          data: data,
          class: class_names(trigger_classes, @system_arguments[:class])
        ) do
          label = content_tag(:span, @label, class: 'flex-1')
          caret = content_tag(:span, '›', class: 'text-slate-500 dark:text-slate-400')
          label + caret
        end

        submenu = content_tag(
          :div,
          id: @menu_id,
          role: 'menu',
          tabindex: -1,
          hidden: true,
          'aria-labelledby': @trigger_id,
          data: {
            'pathogen--dropdown-menu-target': 'menu',
            submenu: 'true',
            parent_menu_id: @parent_menu_id,
            state: 'closed',
            action: submenu_actions
          },
          class: submenu_classes
        ) do
          content_tag(:div, class: 'py-1', role: 'presentation') do
            safe_join(@entries.map { |entry| render(entry) })
          end
        end

        safe_join([trigger, submenu])
      end

      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
