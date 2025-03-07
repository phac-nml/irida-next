# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering an group sample activity
    class SampleActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def import_samples_action
        @activity[:action] == 'import_samples'
      end
    end
  end
end
