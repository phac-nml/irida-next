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
      @system_arguments[:classes] ||= 'py-2.5 px-5 mr-2 mb-2 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700' # rubocop:disable Layout/LineLength
      @system_arguments[:classes] = class_names(
        'flex items-center',
        @system_arguments[:classes]
      )
      @system_arguments
    end

    def system_arguments_for_icon
      @system_arguments[:classes] ||= 'rounded-full text-sm text-gray-500 p-2.5 hover:bg-gray-100 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-700'
      @system_arguments
    end
  end
end
