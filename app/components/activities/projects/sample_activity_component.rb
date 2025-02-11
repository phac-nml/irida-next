# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an project sample activity
    class SampleActivityComponent < BaseActivityComponent
      include PathHelper

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
