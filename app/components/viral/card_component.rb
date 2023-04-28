# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class CardComponent < Viral::Component
    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end

    def system_arguments
      @system_arguments.merge(classes: 'p-4 bg-white border border-gray-200 rounded-lg shadow-sm 2xl:col-span-2 dark:border-gray-700 sm:p-6 dark:bg-gray-800')
    end
  end
end
