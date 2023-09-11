# frozen_string_literal: true

module Viral
  module Form
    class CheckboxComponent < Viral::Component
      attr_reader :label, :default, :help_text

      def initialize(label:, default: false, help_text: nil, hidden: false, **arguments)
        @label = label
        @default = default
        @help_text = help_text
        @hidden = hidden
        @arguments = arguments
      end

      def system_arguments
        @arguments.tap do |args|
          args[:tag] = 'div'
          args[:classes] = class_names('mb-4', args[:classes], @hidden ? 'hidden' : '')
          args['aria-hidden'] = @hidden
        end
      end
    end
  end
end
