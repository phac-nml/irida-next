# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Projects
  class GroupActivityComponent < Component
    def initialize(activity: nil)
      @activity = activity
    end

    def project_link
      @activity[:group] && @activity[:project] && !@activity[:project].namespace.nil?
    end

    def group_link
      (@activity[:transferred_group] && @activity[:action] == 'group_namespace_transfer') ||
        (@activity[:created_group] && @activity[:action] == 'group_subgroup_create')
    end

    def transfer_out
      @activity[:key].include?('transfer_out')
    end

    def metadata_template_link
      metadata_template_action_types = %w[metadata_template_create metadata_template_update metadata_template_destroy]
      metadata_template_action_types.include?(@activity[:action])
    end
  end
end
