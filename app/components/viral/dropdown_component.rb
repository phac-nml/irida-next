# frozen_string_literal: true

module Viral
  # Dropdown component
  class DropdownComponent < Viral::Component
    renders_many :items, Dropdown::ItemComponent

    TRIGGER_DEFAULT = :click
    TRIGGER_MAPPINGS = {
      click: 'click',
      hover: 'hover'
    }.freeze

    def initialize(label: nil, icon: nil, caret: false, trigger: TRIGGER_DEFAULT,
                   **system_arguments)
      @label = label
      @icon_name = icon
      @caret = caret
      @trigger = TRIGGER_MAPPINGS[trigger]

      @system_arguments = system_arguments
      @system_arguments[:data] = { 'viral--dropdown-target': 'trigger' }
      @system_arguments[:tag] = :button

      @system_arguments = system_arguments_for_button if @label.present?

      return if @icon_name.blank?

      @system_arguments = system_arguments_for_icon
    end

    def system_arguments_for_button
      @system_arguments[:classes] = class_names(
        'Viral-Dropdown--button',
        @system_arguments[:classes]
      )
      @system_arguments
    end

    def system_arguments_for_icon
      @system_arguments[:classes] = class_names(
        'Viral-Dropdown--icon',
        @system_arguments[:classes]
      )
      @system_arguments
    end
  end
end
