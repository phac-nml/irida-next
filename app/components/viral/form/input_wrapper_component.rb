# frozen_string_literal: true

module Viral
  module Form
    # Wrapper for form inputs providing label and help text
    class InputWrapperComponent < Viral::Component
      attr_reader :label, :help_text, :name

      def initialize(label:, name:, hidden:, help_text: nil, **args)
        @label = label
        @name = name
        @help_text = help_text
        @args = args
        @hidden = hidden
      end

      def system_arguments
        @args.tap do |opts|
          opts[:tag] = 'div'
          opts[:classes] = class_names('hidden') if @hidden
        end
      end
    end
  end
end
