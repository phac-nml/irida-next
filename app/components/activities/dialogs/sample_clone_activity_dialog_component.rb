# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering project sample clone activity dialog
    class SampleCloneActivityDialogComponent < Component
      attr_accessor :activity, :activity_owner

      def initialize(activity: nil, extended_details: nil, activity_owner: nil)
        @activity = activity
        @activity[:parameters] = @activity.parameters.transform_keys(&:to_sym)
        @extended_details = extended_details
        @activity_owner = activity_owner
      end
    end
  end
end
