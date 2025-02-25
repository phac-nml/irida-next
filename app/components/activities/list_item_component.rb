# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < Component
    attr_accessor :activity

    def initialize(activity: nil)
      @activity = activity
    end

    def member_action
      %w[member_create member_update member_destroy].include?(@activity[:action])
    end

    def metadata_template_action
      %w[metadata_template_create metadata_template_destroy metadata_template_update].include?(@activity[:action])
    end

    def project_crud_action
      @activity[:key].include?('group.projects.create') ||  @activity[:key].include?('group.projects.destroy')
    end

    def project_namespace_transfer_action
      %w[project_namespace_transfer].include?(@activity[:action])
    end

    def sample_clone_action
      %w[sample_clone].include?(@activity[:action])
    end

    def sample_action
      %w[sample_create sample_update attachment_create attachment_destroy
         metadata_update sample_destroy sample_destroy_multiple].include?(@activity[:action])
    end

    def sample_transfer_action
      %w[sample_transfer].include?(@activity[:action])
    end

    def subgroup_action
      @activity[:action] == 'group_subgroup_destroy' || (@activity[:action] == 'group_subgroup_create') ||
        (@activity[:action] == 'group_namespace_transfer')
    end

    def transfer_in_action
      @activity[:key].include?('group.transfer_in')
    end

    def transfer_out_action
      @activity[:key].include?('group.transfer_out')
    end

    def project_transfer_action
      @activity[:action] == 'project_namespace_transfer'
    end
  end
end
