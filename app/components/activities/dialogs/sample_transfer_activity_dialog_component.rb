# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering project sample transfer activity dialog
    class SampleTransferActivityDialogComponent < Component
      attr_accessor :activity

      def initialize(activity = nil)
        @activity = activity
      end
    end
  end
end
