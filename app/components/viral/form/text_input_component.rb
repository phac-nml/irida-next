# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TextInputComponent < Viral::Component
      attr_reader :label, :name, :help_text

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label:, type: 'text', default: nil, required: false, help_text: nil, **arguments)
        @name = name
        @label = label
        @type = type
        @default = default
        @required = required
        @help_text = help_text
        @arguments = arguments
      end

      # rubocop:enable Metrics/ParameterLists

      def system_arguments
        @arguments.tap do |args|
          args[:tag] = 'input'
          args[:type] = @type == 'integer' ? 'number' : @type
          args[:name] = @name
          args[:id] = @name
          args[:value] = @default
          args[:required] = @required
          args[:classes] = class_names(
            'bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500',
            args[:classes]
          )
        end
      end
    end
  end
end
