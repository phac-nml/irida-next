# frozen_string_literal: true

module Viral
  module Form
    # Form select input component
    class SelectComponent < Viral::Component
      attr_reader :container, :label, :name, :options, :selected_value, :multiple

      def initialize(container:, name:, options: [], multiple: false, selected_value: nil)
        @container = container
        @name = name
        @multiple = multiple
        @selected_value = selected_value
        @options = options
      end
    end
  end
end
