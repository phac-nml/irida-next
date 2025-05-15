# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering group sample transfer activity
    class SampleTransferActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end
    end
  end
end
