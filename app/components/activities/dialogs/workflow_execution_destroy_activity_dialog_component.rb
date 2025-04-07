# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering project sample transfer activity dialog
    class WorkflowExecutionDestroyActivityDialogComponent < Component
      attr_accessor :activity, :activity_owner

      def initialize(activity: nil, activity_owner: nil)
        @activity = activity
        @activity[:parameters] = @activity.parameters.transform_keys(&:to_sym)
        @activity[:parameters][:workflow_executions] =
          @activity[:parameters][:workflow_executions].map(&:symbolize_keys)
        @activity_owner = activity_owner
      end
    end
  end
end
