# frozen_string_literal: true

module Viral
  module Form
    # Checkbox component
    class CheckboxComponent < Viral::Component
      attr_reader :label, :name, :value, :checked, :help_text

      def initialize(name:, value:, label:, checked: false, help_text: nil, hidden: false, **arguments) # rubocop:disable Metrics/ParameterLists
        @name = name
        @value = value
        @label = label
        @checked = checked
        @help_text = help_text
        @hidden = hidden
        @arguments = arguments
      end

      def system_arguments
        @arguments.tap do |args|
          args[:tag] = 'div'
          args[:classes] = class_names('mb-4', args[:classes], @hidden ? 'hidden' : nil)
          args['aria-hidden'] = @hidden
        end
      end
    end
  end
end
