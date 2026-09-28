# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < BaseActivityComponent # rubocop:disable Metrics/ClassLength
    attr_accessor :activity

    def group_link_action?
      %w[group_link_create group_link_destroy group_link_update group_link_created group_link_destroyed
         group_link_updated].include?(@activity[:action])
    end

    def member_action?
      %w[member_create member_update member_destroy].include?(@activity[:action])
    end

    def metadata_template_action?
      %w[metadata_template_create metadata_template_destroy metadata_template_update].include?(@activity[:action])
    end

    def project_crud_action?
      @activity[:key].include?('group.projects.create') || @activity[:key].include?('group.projects.destroy')
    end

    def project_namespace_transfer_action?
      %w[project_namespace_transfer].include?(@activity[:action])
    end

    def sample_clone_action?
      %w[sample_clone group_sample_clone].include?(@activity[:action])
    end

    def sample_action?
      %w[sample_create sample_update attachment_create attachment_destroy
         metadata_update sample_destroy sample_destroy_multiple group_samples_destroy project_import_samples
         group_import_samples project_bulk_metadata_update group_bulk_metadata_update].include?(@activity[:action])
    end

    def sample_transfer_action?
      %w[group_sample_transfer sample_transfer].include?(@activity[:action])
    end

    def subgroup_action?
      @activity[:action] == 'group_subgroup_destroy' || (@activity[:action] == 'group_subgroup_create') ||
        (@activity[:action] == 'group_namespace_transfer')
    end

    def transfer_in_action?
      @activity[:key].include?('group.transfer_in')
    end

    def transfer_out_action?
      @activity[:key].include?('group.transfer_out')
    end

    def project_transfer_action?
      @activity[:action] == 'project_namespace_transfer'
    end

    def project_namespace_workflow_execution_action?
      @activity[:action] == 'workflow_execution_destroy'
    end

    # Selects which activity component to render for the current activity.
    def activity_component
      if @activity[:type] == 'Namespace' && @activity[:key].include?('group')
        group_activity_component
      elsif @activity[:type] == 'Namespace' && @activity[:key].include?('project_namespace')
        project_namespace_activity_component
      elsif @activity[:type] == 'WorkflowExecution'
        Activities::WorkflowExecutionActivityComponent.new(activity: @activity)
      end
    end

    private

    def group_activity_component # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
      if metadata_template_action?
        Activities::Groups::MetadataTemplateActivityComponent.new(activity: @activity)
      elsif transfer_in_action?
        Activities::Groups::TransferInActivityComponent.new(activity: @activity)
      elsif transfer_out_action?
        Activities::Groups::TransferOutActivityComponent.new(activity: @activity)
      elsif subgroup_action?
        Activities::Groups::SubgroupActivityComponent.new(activity: @activity)
      elsif sample_transfer_action?
        Activities::Groups::SampleTransferActivityComponent.new(activity: @activity)
      elsif sample_clone_action?
        Activities::Groups::SampleCloneActivityComponent.new(activity: @activity)
      elsif member_action?
        Activities::MemberActivityComponent.new(activity: @activity)
      elsif project_crud_action?
        Activities::Groups::Projects::CrudActivityComponent.new(activity: @activity)
      elsif project_transfer_action?
        Activities::Groups::Projects::TransferActivityComponent.new(activity: @activity)
      elsif group_link_action?
        Activities::NamespaceGroupLinkActivityComponent.new(activity: @activity)
      elsif sample_action?
        Activities::Groups::SampleActivityComponent.new(activity: @activity)
      else
        Activities::GroupActivityComponent.new(activity: @activity)
      end
    end

    def project_namespace_activity_component # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      if group_link_action?
        Activities::NamespaceGroupLinkActivityComponent.new(activity: @activity)
      elsif metadata_template_action?
        Activities::Projects::MetadataTemplateActivityComponent.new(activity: @activity)
      elsif sample_action?
        Activities::Projects::SampleActivityComponent.new(activity: @activity)
      elsif sample_transfer_action?
        Activities::Projects::SampleTransferActivityComponent.new(activity: @activity)
      elsif sample_clone_action?
        Activities::Projects::SampleCloneActivityComponent.new(activity: @activity)
      elsif member_action?
        Activities::MemberActivityComponent.new(activity: @activity)
      elsif project_namespace_transfer_action?
        Activities::Projects::TransferActivityComponent.new(activity: @activity)
      elsif project_namespace_workflow_execution_action?
        Activities::Projects::WorkflowExecutionActivityComponent.new(activity: @activity)
      else
        Activities::Projects::BaseActivityComponent.new(activity: @activity)
      end
    end
  end
end
