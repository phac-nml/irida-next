# frozen_string_literal: true

module Viral
  module Form
    module Prefixed
      # Select component with a prefix
      class SelectComponent < Viral::Component
        attr_reader :form, :name, :options, :selected_value, :on_change, :select_classes

        renders_one :prefix

        def initialize(form:, name:, options: [], selected_value: false, on_change: '', select_classes: '') # rubocop: disable Metrics/ParameterLists
          @form = form
          @name = name
          @options = options
          @selected_value = selected_value
          @on_change = on_change
          @select_classes = class_names(select_classes, 'rounded-none rounded-e-lg bg-slate-50 border text-slate-900 block flex-1 min-w-0 w-full text-sm border-slate-300 p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-slate-400 dark:text-white') # rubocop:disable Layout/LineLength
        end
      end
    end
  end
end
