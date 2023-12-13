# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TextInputComponent < Viral::Component
      attr_reader :container, :name, :value, :required, :pattern, :placeholder

      # rubocop:disable Metrics/ParameterLists
      def initialize(container:, name:, value: nil, required: nil, pattern: nil, placeholder: nil)
        @container = container
        @name = name
        @value = value
        @required = required
        @pattern = pattern
        @placeholder = placeholder
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
