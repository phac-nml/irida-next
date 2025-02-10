# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < Component
    attr_accessor :activity

    def initialize(activity: nil)
      @activity = activity
    end

    def metadata_template_action
      %w[metadata_template_create metadata_template_destroy metadata_template_update].include?(@activity[:action])
    end

    def project_namespace_transfer_action
      %w[project_namespace_transfer].include?(@activity[:action])
    end

    def sample_clone_action
      %w[sample_clone].include?(@activity[:action])
    end

    def sample_action
      %w[sample_create sample_update attachment_create attachment_destroy
         metadata_update sample_destroy_multiple].include?(@activity[:action])
    end

    def sample_transfer_action
      %w[sample_transfer].include?(@activity[:action])
    end
  end
end
