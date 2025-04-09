# frozen_string_literal: true

module Viral
  module Form
    # Form control for datepicker
    class DatepickerComponent < Viral::Component
      attr_reader :name, :label, :help_text

      def initialize(id:, name:, label: nil, value: nil, help_text: nil, **options) # rubocop:disable Metrics/ParameterLists
        @id = id.presence || name
        @name = name
        @label = label
        @value = value
        @help_text = help_text
        @options = options
      end

      def system_arguments
        @options.tap do |opts|
          opts[:id] = @id
          opts[:class] = class_names(
            'border border-slate-300 text-slate-900 sm:text-sm rounded-md',
            'block w-full pl-10 p-2.5 dark:bg-slate-800 dark:border-slate-600',
            'dark:placeholder-slate-400 dark:text-white'
          )
          opts[:data] = {
            datepicker_target: 'datePicker'
          }
        end
      end
    end
  end
end
