# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering group sample clone activity
    class SampleCloneActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end
    end
  end
end
