# frozen_string_literal: true

module Viral
  # Dropdown component
  class DropdownComponent < Viral::Component
    renders_one :trigger, lambda { |**system_arguments|
      system_arguments[:classes] ||= 'py-2.5 px-5 mr-2 mb-2 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700' # rubocop:disable Layout/LineLength
      system_arguments[:data] = { 'viral--dropdown-target': 'trigger' }
      Viral::BaseComponent.new(tag: :button, **system_arguments)
    }

    renders_many :items, Dropdown::ItemComponent
  end
end
