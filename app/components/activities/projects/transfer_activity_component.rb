# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an activity of type Namespace for Projects
    class TransferActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end
    end
  end
end
