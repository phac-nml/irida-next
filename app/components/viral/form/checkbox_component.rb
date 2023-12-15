# frozen_string_literal: true

module Viral
  module Form
    # Checkbox component
    class CheckboxComponent < Viral::Component
      attr_reader :container, :label, :name, :value, :checked

      def initialize(container:, name:, value:, label:, checked:)
        @container = container
        @name = name
        @value = value
        @label = label
        @checked = checked
      end
    end
  end
end
