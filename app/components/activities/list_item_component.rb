# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < Component
    attr_accessor :activity

    def initialize(activity: nil)
      @activity = activity
    end

    def group_link_action
      %w[group_link_create group_link_destroy group_link_update group_link_created group_link_destroyed
         group_link_updated].include?(@activity[:action])
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
         metadata_update sample_destroy project_sample_destroy_multiple group_samples_destroy project_import_samples
         group_import_samples].include?(@activity[:action])
    end

    def sample_transfer_action
      %w[group_sample_transfer sample_transfer].include?(@activity[:action])
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

    def project_namespace_workflow_execution_action
      @activity[:action] == 'workflow_execution_destroy'
    end
  end
end
