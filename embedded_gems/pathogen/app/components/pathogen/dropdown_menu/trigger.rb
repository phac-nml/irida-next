# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Trigger component for DropdownMenu.
    #
    # Renders a button that controls the dropdown menu.
    class Trigger < Pathogen::Component
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def initialize(id:, menu_id:, aria_label: nil, **system_arguments)
        @id = id
        @menu_id = menu_id
        @system_arguments = system_arguments

        @system_arguments[:id] = @id
        @system_arguments[:tag] = :button
        @system_arguments[:type] = :button
        @system_arguments[:'aria-haspopup'] = 'menu'
        @system_arguments[:'aria-expanded'] = 'false'
        @system_arguments[:'aria-controls'] = @menu_id
        @system_arguments[:'aria-label'] = aria_label if aria_label.present?

        @system_arguments[:data] ||= {}
        existing_action = @system_arguments.dig(:data, :action) || @system_arguments.dig(:data, 'action')
        @system_arguments[:data]['pathogen--dropdown-menu-target'] = 'trigger'
        @system_arguments[:data][:action] = class_names(
          existing_action,
          'click->pathogen--dropdown-menu#toggle',
          'keydown->pathogen--dropdown-menu#onTriggerKeydown'
        )

        @system_arguments[:class] = class_names(
          'inline-flex items-center justify-center gap-2 rounded-lg',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600',
          @system_arguments[:class]
        )
      end

      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def call
        content_tag(:button, content, **@system_arguments.except(:tag))
      end
    end
  end
end
