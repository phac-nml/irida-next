# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an activity of type Namespace for samples
    class SampleActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end

      def samples_tab
        @activity[:action] == 'metadata_update' ? 'metadata' : ''
      end

      def sample_destroy_multiple_action
        @activity[:action] == 'sample_destroy_multiple'
      end
    end
  end
end
