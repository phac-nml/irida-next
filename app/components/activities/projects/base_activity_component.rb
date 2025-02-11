# frozen_string_literal: true

module Activities
  module Projects
    # Base Component for rendering an activity of type Namespace for Projects
    class BaseActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end
    end
  end
end
