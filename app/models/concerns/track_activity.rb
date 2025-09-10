# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Common
  end

  def human_readable_activity(public_activities) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
    activities = []
    public_activities.each do |activity|
      next if !activity.parameters[:member_email].nil? && activity.parameters[:member_email].include?('automation')

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
      end
    end

    activities
  end

  private

  def project_activity(activity) # rubocop:disable Metrics/MethodLength
    activity_trackable = activity_trackable(activity, Project)

    base_params = {
      id: activity.id,
      created_at: activity.created_at,
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      current_project: activity_trackable,
      name: activity_trackable.name,
      type: 'Namespace',
      action: activity.parameters.key?(:action) ? activity.parameters[:action] : 'default'
    }

    return base_params if activity.parameters[:action].blank?

    params = member_activity_params(activity, activity_trackable, base_params)
    params = group_link_params(activity, params)
    params = transfer_activity_parameters(params, activity)
    params = workflow_execution_activity_params(params, activity)

    namespace_project_sample_activity_parameters(params, activity)
  end

  def group_activity(activity) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_trackable = activity_trackable(activity, Group)

    base_params = {
      id: activity.id,
      created_at: activity.created_at,
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

    params = member_activity_params(activity, activity_trackable, base_params)
    params = group_link_params(activity, params)
    params = transfer_activity_parameters(params, activity)
    params = additional_group_activity_params(params, activity)
    params = add_bulk_sample_params(params, activity)

    transfer_activity_parameters(params, activity)
  end

  def workflow_execution_activity(activity) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_trackable = activity_trackable(activity, Namespace)

    base_params = {
      id: activity.id,
      created_at: activity.created_at,
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

    base_params.merge!({
                         workflow_execution: get_object_by_id(activity.parameters[:workflow_id], relation),
                         sample: get_object_by_id(activity.parameters[:sample_id], Sample)
                       })
  end

  def member_activity_params(activity, activity_trackable, params)
    member_action_types = %w[member_create member_destroy member_update]
    return params unless member_action_types.include?(activity.parameters[:action])

    member = Member.joins(:user, :namespace).with_deleted.where(user: { email: activity.parameters[:member_email] },
                                                                namespace: { id: activity_trackable.id }).last

    params.merge!(member: member, member_email: activity.parameters[:member_email])
  end

  def group_link_params(activity, params) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    group_link_namespace_action_types = %w[group_link_create group_link_destroy group_link_update]
    group_link_group_action_types = %w[group_link_created group_link_destroyed group_link_updated]

    unless group_link_namespace_action_types.include?(activity.parameters[:action]) ||
           group_link_group_action_types.include?(activity.parameters[:action])
      return params
    end

    group_link = NamespaceGroupLink.joins(:namespace, :group).with_deleted.where(
      group: { puid: activity.parameters[:group_puid] },
      namespace: { puid: activity.parameters[:namespace_puid] }
    ).last

    params.merge!({ group_link: group_link,
                    group_puid: activity.parameters[:group_puid],
                    group_name: activity.parameters[:group_name],
                    namespace_puid: activity.parameters[:namespace_puid],
                    namespace_name: activity.parameters[:namespace_name],
                    namespace_type: activity.parameters[:namespace_type] })
  end

  def activity_creator(activity)
    return activity.owner.email unless activity.owner.nil?

    unless activity.owner_id.nil?
      user = get_object_by_id(activity.owner_id, User)
      return user.email unless user.nil?
    end

    I18n.t('activerecord.concerns.track_activity.system')
  end

  def activity_trackable(activity, relation)
    activity.trackable.nil? ? get_object_by_id(activity.trackable_id, relation) : activity.trackable
  end

  def get_object_by_id(identifier, relation)
    if relation == Project
      proj = relation.with_deleted.find_by(id: identifier)&.namespace_id
      Namespace.with_deleted.find_by(id: proj) if proj.present?
    else
      relation.with_deleted.find_by(id: identifier)
    end
  rescue StandardError
    # acts_as_paranoid not setup on model
    relation.find_by(id: identifier)
  end

  def get_object_by_puid(puid, relation)
    relation.with_deleted.find_by(puid: puid)
  rescue StandardError
    # acts_as_paranoid not setup on model
    relation.find_by(puid: puid)
  end

  def transfer_activity_parameters(params, activity) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
    if %w[project_namespace_transfer group_namespace_transfer].include?(activity.parameters[:action])

      params.merge!({
                      old_namespace: activity.parameters[:old_namespace],
                      new_namespace: activity.parameters[:new_namespace]
                    })
    end

    if activity.parameters[:action] == 'project_namespace_transfer'
      params.merge!({ project: get_object_by_id(activity.parameters[:project_id], Project),
                      project_puid: activity.parameters[:project_puid] })
    end

    if activity.parameters[:action] == 'group_namespace_transfer'
      params.merge!({ transferred_group: get_object_by_id(activity.parameters[:transferred_group_id], Group),
                      transferred_group_puid: activity.parameters[:transferred_group_puid] })
    end

    if activity.parameters[:action] == 'sample_transfer'
      params.merge!({
                      source_project_puid: activity.parameters[:source_project_puid],
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project_puid: activity.parameters[:target_project_puid],
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      transferred_samples_count: activity.parameters[:transferred_samples_count]
                    })
    end

    if activity.parameters[:action] == 'group_sample_transfer'
      params.merge!({
                      transferred_samples_count: activity.parameters[:transferred_samples_count]
                    })
    end

    if activity.parameters[:action] == 'sample_clone'
      params.merge!({
                      source_project_puid: activity.parameters[:source_project_puid],
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project_puid: activity.parameters[:target_project_puid],
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      cloned_samples_count: activity.parameters[:cloned_samples_count]
                    })
    end

    if activity.parameters[:action] == 'group_sample_clone'
      params.merge!({
                      cloned_samples_count: activity.parameters[:cloned_samples_count]
                    })
    end

    params
  end

  def workflow_execution_activity_params(params, activity)
    if activity.parameters[:action] == 'workflow_execution_destroy'
      params.merge!({
                      workflow_executions_deleted_count: activity.parameters[:workflow_executions_deleted_count]
                    })
    end
    params
  end

  def namespace_project_sample_activity_parameters(params, activity)
    params = add_sample_activity_params(params, activity)
    params = add_metadata_template_params(params, activity)
    params = add_samples_import_params(params, activity)
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

  def add_samples_import_params(params, activity)
    return params unless %w[group_import_samples project_import_samples].include?(activity.parameters[:action])

    params.merge(
      imported_samples_count: activity.parameters[:imported_samples_count]
    )
  end

  def add_bulk_sample_params(params, activity)
    return params unless %w[sample_destroy_multiple group_samples_destroy].include?(activity.parameters[:action])

    params.merge(
      samples_deleted_count: activity.parameters[:samples_deleted_count]
    )
  end

  def additional_group_activity_params(params, activity) # rubocop:disable Metrics/AbcSize
    params = add_metadata_template_params(params, activity)
    params = add_samples_import_params(params, activity)

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

    params.merge!({ created_group: get_object_by_id(activity.parameters[:created_group_id], Group),
                    created_group_puid: activity.parameters[:created_group_puid] })
  end

  # convert string keys to symbols
  def convert_activity_parameter_keys(activity)
    activity.parameters.transform_keys(&:to_sym)
  end
end
