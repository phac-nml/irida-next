# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Common
  end

  def human_readable_activity(public_activities) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    activities = []
    public_activities.each do |activity|
      trackable_type = activity.trackable_type
      activity[:parameters] = convert_activity_parameter_keys(activity)

      case trackable_type
      when 'Namespace'
        if activity.key.include?('project_namespace')
          activities << project_activity(activity)
        elsif activity.key.include?('group')
          activities << group_activity(activity)
        elsif activity.key.include?('workflow_execution')
          activities << workflow_execution_activity(activity)
        end
      when 'Member'
        activities << member_activity(activity)
      when 'NamespaceGroupLink'
        activities << namespace_group_link_activity(activity)
      end
    end

    activities
  end

  private

  def project_activity(activity)
    activity_trackable = activity_trackable(activity, Project)

    base_params = {
      created_at: format_created_at(activity.created_at),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      current_project: activity_trackable,
      name: activity_trackable.name,
      type: 'Namespace',
      action: activity.parameters.key?(:action) ? activity.parameters[:action] : 'default'
    }

    return base_params if activity.parameters[:action].blank?

    params = transfer_activity_parameters(base_params, activity)

    namespace_project_sample_activity_parameters(params, activity)
  end

  def group_activity(activity) # rubocop:disable Metrics/AbcSize
    activity_trackable = activity_trackable(activity, Group)

    base_params = {
      created_at: format_created_at(activity.created_at),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      group: activity_trackable,
      project: get_object_by_id(activity.parameters[:project_id], Project),
      project_puid: activity.parameters[:project_puid],
      name: activity_trackable.name,
      type: 'Namespace',
      action: activity.parameters.key?(:action) ? activity.parameters[:action] : 'default'
    }

    return base_params if activity.parameters[:action].blank?

    params = additional_group_activity_params(base_params, activity)

    transfer_activity_parameters(params, activity)
  end

  def workflow_execution_activity(activity)
    activity_trackable = activity_trackable(activity, Namespace)

    base_params = {
      created_at: format_created_at(activity.created_at),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      namespace: activity_trackable,
      workflow_id: activity.parameters[:workflow_id],
      type: 'WorkflowExecution',
      sample_puid: activity.parameters[:sample_puid],
      sample_id: activity.parameters[:sample_id],
      automated: activity.parameters[:automated]
    }

    relation = activity.parameters[:automated] == true ? AutomatedWorkflowExecution : WorkflowExecution

    base_params.merge!({ workflow_execution: get_object_by_id(activity.parameters[:workflow_id], relation) })
  end

  def member_activity(activity)
    activity_trackable = activity_trackable(activity, Member)

    {
      created_at: format_created_at(activity.created_at),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      namespace_type: activity_trackable.namespace.type.downcase,
      name: activity_trackable.namespace.name,
      member: activity_trackable,
      type: 'Member'
    }
  end

  def namespace_group_link_activity(activity)
    activity_trackable = activity_trackable(activity, NamespaceGroupLink)

    {
      created_at: format_created_at(activity.created_at),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      namespace_type: activity_trackable.namespace.type.downcase,
      name: activity_trackable.namespace.name,
      group: activity_trackable.group,
      namespace: activity_trackable.namespace,
      type: 'NamespaceGroupLink'
    }
  end

  def activity_creator(activity)
    activity.owner.nil? ? I18n.t('activerecord.concerns.track_activity.system') : activity.owner.email
  end

  def activity_trackable(activity, relation)
    activity.trackable.nil? ? get_object_by_id(activity.trackable_id, relation) : activity.trackable
  end

  def get_object_by_id(identifier, relation)
    if relation == Project
      proj = relation.with_deleted.find_by(id: identifier)&.namespace_id
      Namespace.with_deleted.find_by(id: proj) if proj.present?
    elsif relation.method_defined?(:with_deleted)
      relation.with_deleted.find_by(id: identifier)
    else
      relation.find_by(id: identifier)
    end
  end

  def get_object_by_puid(puid, relation)
    if relation.method_defined?(:with_deleted)
      relation.with_deleted.find_by(puid: puid)
    else
      relation.find_by(puid: puid)
    end
  end

  def transfer_activity_parameters(params, activity) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    if %w[project_namespace_transfer group_namespace_transfer].include?(activity.parameters[:action])

      params.merge!({
                      old_namespace: activity.parameters[:old_namespace],
                      new_namespace: activity.parameters[:new_namespace]
                    })
    end

    if activity.parameters[:action] == 'group_namespace_transfer'
      params.merge!({ transferred_group: get_object_by_id(activity.parameters[:transferred_group_id], Group) })
    end

    if activity.parameters[:action] == 'sample_transfer'
      params.merge!({
                      source_project_puid: activity.parameters[:source_project_puid],
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project_puid: activity.parameters[:target_project_puid],
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      transferred_samples_ids: activity.parameters[:transferred_samples_ids],
                      transferred_samples_puids: activity.parameters[:transferred_samples_puids]
                    })
    end

    if activity.parameters[:action] == 'sample_clone'
      params.merge!({
                      source_project_puid: activity.parameters[:source_project_puid],
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project_puid: activity.parameters[:target_project_puid],
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      cloned_samples_ids: activity.parameters[:cloned_samples_ids],
                      cloned_samples_puids: activity.parameters[:cloned_samples_puids]
                    })
    end

    params
  end

  def namespace_project_sample_activity_parameters(params, activity)
    params = add_sample_activity_params(params, activity)
    params = add_metadata_template_params(params, activity)
    add_bulk_sample_params(params, activity)
  end

  def add_sample_activity_params(params, activity)
    sample_activity_action_types = %w[sample_create sample_update metadata_update sample_destroy attachment_create
                                      attachment_destroy sample_destroy]
    return params unless sample_activity_action_types.include?(activity.parameters[:action])

    params.merge(
      sample_id: activity.parameters[:sample_id],
      sample_puid: activity.parameters[:sample_puid],
      sample: get_object_by_puid(activity.parameters[:sample_puid], Sample)
    )
  end

  def add_metadata_template_params(params, activity)
    metadata_template_action_types = %w[metadata_template_create metadata_template_update metadata_template_destroy]
    return params unless metadata_template_action_types.include?(activity.parameters[:action])

    params.merge(
      template_id: activity.parameters[:template_id],
      template_name: activity.parameters[:template_name],
      template: get_object_by_id(activity.parameters[:template_id], MetadataTemplate)
    )
  end

  def add_bulk_sample_params(params, activity)
    return params unless activity.parameters[:action] == 'sample_destroy_multiple'

    params.merge(
      deleted_count: activity.parameters[:deleted_count],
      samples_deleted_puids: activity.parameters[:samples_deleted_puids]
    )
  end

  def format_created_at(created_at)
    created_at.strftime(I18n.t('time.formats.abbreviated'))
  end

  def additional_group_activity_params(params, activity)
    if activity.parameters[:action] == 'group_subgroup_destroy'
      params.merge!({ removed_group_puid: activity.parameters[:removed_group_puid] })
    end

    metadata_template_action_types = %w[metadata_template_create metadata_template_update metadata_template_destroy]
    if metadata_template_action_types.include?(activity.parameters[:action])
      params.merge!({
                      template_id: activity.parameters[:template_id],
                      template_name: activity.parameters[:template_name]
                    })
    end

    return params unless activity.parameters[:action] == 'group_subgroup_create'

    params.merge!({ created_group: get_object_by_id(activity.parameters[:created_group_id], Group) })
  end

  # convert string keys to symbols
  def convert_activity_parameter_keys(activity)
    activity.parameters.transform_keys(&:to_sym)
  end
end
