# frozen_string_literal: true

module Viral
  module Form
    # Form control for datepicker
    class DatepickerComponent < Viral::Component
      attr_reader :name, :label, :help_text

      def initialize(id:, name:, label: nil, value: nil, help_text: nil, **options) # rubocop:disable Metrics/ParameterLists
        @id = id
        @name = name
        @label = label
        @value = value
        @help_text = help_text
        @options = options
      end

      def system_arguments
        @options.tap do |opts|
          opts[:tag] = 'input'
          opts[:type] = 'text'
          opts[:name] = @name
          opts[:id] = @id
          opts[:value] = @value
          opts[:classes] = class_names(
            'border border-slate-300 text-slate-900 sm:text-sm rounded-md focus:ring-primary-700',
            'focus:border-primary-700 block w-full pl-10 p-2.5 dark:bg-slate-800 dark:border-slate-600',
            'dark:placeholder-slate-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500'
          )
          opts[:data] = {
            datepicker_target: 'datePicker'
          }
        end
      end
    end
  end
end
