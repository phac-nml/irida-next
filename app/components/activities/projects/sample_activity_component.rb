# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an project sample activity
    class SampleActivityComponent < BaseActivityComponent
      def sample_destroy_multiple_action
        @activity[:action] == 'sample_destroy_multiple'
      end

      def sample_exists(sample)
        return false if sample.nil?
        return false if sample.project.namespace != @activity[:current_project]

        !sample.deleted?
      end

      def samples_tab
        @activity[:action] == 'metadata_update' ? 'metadata' : ''
      end

      def import_samples_action
        @activity[:action] == 'import_samples'
      end
    end
  end
end
