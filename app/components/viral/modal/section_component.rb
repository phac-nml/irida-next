# frozen_string_literal: true

module Viral
  module Modal
    # Section component for a modal dialog.
    class SectionComponent < Viral::Component
      def initialize(**system_arguments)
        @system_arguments = system_arguments
        @system_arguments[:classes] = class_names(@system_arguments[:classes],
                                                  'dialog--section')
      end
    end
  end
end
