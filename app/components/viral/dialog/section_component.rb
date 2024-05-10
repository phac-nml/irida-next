# frozen_string_literal: true

module Viral
  module Dialog
    # Section component for a dialog.
    class SectionComponent < Viral::Component
      def initialize(**system_arguments)
        @system_arguments = system_arguments
        @system_arguments[:classes] = class_names(@system_arguments[:classes],
                                                  'p-5')
      end
    end
  end
end
