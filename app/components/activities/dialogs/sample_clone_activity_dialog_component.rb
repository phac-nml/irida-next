# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering project sample clone activity dialog
    class SampleCloneActivityDialogComponent < Component
      attr_accessor :activity_params

      def initialize(activity_params = nil)
        @activity_params = activity_params
      end
    end
  end
end
