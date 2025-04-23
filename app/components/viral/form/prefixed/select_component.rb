# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Select component with a prefix
      class SelectComponent < Viral::Component
        attr_reader :form, :name, :options, :selected_value

        renders_one :prefix

        def initialize(form:, name:, options: [], selected_value: false, **system_arguments)
          @form = form
          @name = name
          @options = options
          @selected_value = selected_value

          @system_arguments = system_arguments
          @system_arguments[:class] = class_names(
            @system_arguments[:classes],
            'rounded-none rounded-e-lg bg-slate-50 border text-slate-900 block flex-1 min-w-0 w-full text-sm',
            'border-slate-300 p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-slate-400 dark:text-white'
          )
        end
      end
    end
  end
end
