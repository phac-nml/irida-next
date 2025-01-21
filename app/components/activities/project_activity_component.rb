# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Projects
  class ProjectActivityComponent < Component
    include PathHelper

    def initialize(activity: nil)
      @activity = activity
    end

    def sample_link
      %w[sample_create sample_update attachment_create attachment_destroy
         metadata_update].include?(@activity[:action])
      %w[sample_create sample_update attachment_create attachment_destroy
         metadata_update].include?(@activity[:action])
    end

    def samples_link
      %w[sample_clone sample_transfer].include?(@activity[:action])
      %w[sample_clone sample_transfer].include?(@activity[:action])
    end

    def samples_tab
      @activity[:action] == 'metadata_update' ? 'metadata' : ''
    end

    def metadata_template_link
      @activity[:action] == 'metadata_template_create'
    end
  end
end
