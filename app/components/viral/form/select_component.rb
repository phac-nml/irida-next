# frozen_string_literal: true

module Viral
  module Form
    class SelectComponent < Viral::Component
      attr_reader :label, :name, :multiple, :options, :selected_value

      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, name:, options: [], multiple: false, selected_value: nil, **_options)
        @label = label
        @name = name
        @multiple = multiple
        @selected_value = selected_value
        @options = options
      end
    end
  end
end
