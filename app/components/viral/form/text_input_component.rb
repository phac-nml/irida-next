# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TextInputComponent < Viral::Component
      attr_reader :label, :name, :help_text, :hidden

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label:, type: 'text', default: nil, required: nil, pattern: nil, help_text: nil,
                     hidden: false,
                     **arguments)
        @name = name
        @label = label
        @type = type
        @default = default
        @required = required
        @pattern = pattern
        @help_text = help_text
        @hidden = hidden
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
          args[:required] = @required if @required.present?
          args[:pattern] = @pattern if @pattern.present?
          args[:classes] = class_names(
            'bg-slate-50 border border-slate-300 text-slate-900 text-sm rounded-lg focus:ring-primary-500',
            'focus:border-primary-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600',
            'dark:placeholder-slate-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500',
            args[:classes]
          )
        end
      end
    end
  end
end
