# frozen_string_literal: true

module Viral
  module Form
    # Form select input component
    class SelectComponent < Viral::Component
      attr_reader :container, :label, :name, :options, :selected_value, :help_text, :hidden

      # rubocop:disable Metrics/ParameterLists
      def initialize(container:, name:, options: [], multiple: false, help_text: nil,
                     selected_value: nil, hidden: false)
        @container = container
        @name = name
        @multiple = multiple
        @selected_value = selected_value
        @options = options
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
