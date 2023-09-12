# frozen_string_literal: true

module Viral
  module Form
    # Checkbox component
    class CheckboxComponent < Viral::Component
      attr_reader :label, :name, :default, :help_text

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label:, default: false, help_text: nil, hidden: false, **arguments)
        @name = name
        @label = label
        @default = default
        @help_text = help_text
        @hidden = hidden
        @arguments = arguments
      end

      # rubocop:enable Metrics/ParameterLists

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
