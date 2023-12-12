# frozen_string_literal: true

module Viral
  module Form
    # Form select input component
    class SelectComponent < Viral::Component
      attr_reader :container, :label, :name, :options, :selected_value, :help_text, :hidden

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label: nil, container: nil, options: [], multiple: false, help_text: nil,
                     selected_value: nil, hidden: false, **args)
        @container = container
        @label = label
        @name = name
        @multiple = multiple
        @selected_value = selected_value
        @args = args
        @options = options
        @hidden = hidden
        @help_text = help_text
      end

      # rubocop:enable Metrics/ParameterLists

      def system_arguments
        @args.tap do |opts|
          opts[:tag] = 'select'
          opts[:name] = @name
          opts[:multiple] if @multiple
          opts[:classes] = class_names(
            'bg-slate-50 border border-slate-300 text-slate-900',
            'text-sm rounded-lg focus:ring-primary-500', 'focus:border-primary-500 block w-full p-2.5',
            'dark:bg-slate-700 dark:border-slate-600',
            'dark:placeholder-slate-400 dark:text-white',
            'dark:focus:ring-primary-500',
            'dark:focus:border-primary-500'
          )
        end
      end
    end
  end
end
