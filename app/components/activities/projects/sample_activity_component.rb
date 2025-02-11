# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an activity of type Namespace for samples
    class SampleActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end

      def sample_destroy_multiple_action
        @activity[:action] == 'sample_destroy_multiple'
      end

      def sample_exists(sample)
        return false if sample.nil?

        !sample.deleted?
      end

      def samples_tab
        @activity[:action] == 'metadata_update' ? 'metadata' : ''
      end
    end
  end
end
