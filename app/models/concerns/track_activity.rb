# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Common
  end

  def human_readable_activity(public_activities) # rubocop:disable Metrics/MethodLength
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
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
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

  def group_activity(activity)
    activity_trackable = activity_trackable(activity, Group)

    base_params = {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      group: activity_trackable,
      project: get_object_by_id(activity.parameters[:project_id], Project),
      name: activity_trackable.name,
      type: 'Namespace',
      action: activity.parameters.key?(:action) ? activity.parameters[:action] : 'default'
    }

    return base_params if activity.parameters[:action].blank?

    transfer_activity_parameters(base_params, activity)
  end

  def workflow_execution_activity(activity)
    activity_trackable = activity_trackable(activity, Namespace)

    {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      namespace: activity_trackable,
      workflow_id: activity.parameters[:workflow_id],
      type: 'WorkflowExecution',
      sample_puid: activity.parameters[:sample_puid],
      sample_id: activity.parameters[:sample_id],
      automated: activity.parameters[:automated]
    }
  end

  def member_activity(activity)
    activity_trackable = activity_trackable(activity, Member)

    {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
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
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),

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
    relation.with_deleted.find_by(id: identifier)
  end

  def transfer_activity_parameters(params, activity) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    if activity.parameters[:action] == 'project_namespace_transfer' ||
       activity.parameters[:action] == 'group_namespace_transfer'

      params.merge!({
                      old_namespace: activity.parameters[:old_namespace],
                      new_namespace: activity.parameters[:new_namespace]
                    })
    end

    if activity.parameters[:action] == 'sample_transfer'
      params.merge!({
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      transferred_samples_ids: activity.parameters[:transferred_samples_ids],
                      transferred_samples_puids: activity.parameters[:transferred_samples_puids]
                    })
    end

    if activity.parameters[:action] == 'sample_clone'
      params.merge!({
                      source_project: get_object_by_id(activity.parameters[:source_project], Project),
                      target_project: get_object_by_id(activity.parameters[:target_project], Project),
                      cloned_samples_ids: activity.parameters[:cloned_samples_ids],
                      cloned_samples_puids: activity.parameters[:cloned_samples_puids]
                    })
    end

    params
  end

  def namespace_project_sample_activity_parameters(params, activity)
    sample_activity_action_types = %w[sample_create sample_update metadata_update sample_destroy attachment_create
                                      attachment_destroy]

    if sample_activity_action_types.include?(activity.parameters[:action])
      params.merge!({
                      sample_id: activity.parameters[:sample_id],
                      sample_puid: activity.parameters[:sample_puid]
                    })
    end

    if activity.parameters[:action] == 'sample_destroy_multiple'
      params.merge!({
                      deleted_count: activity.parameters[:deleted_count],
                      samples_deleted_puids: activity.parameters[:samples_deleted_puids]
                    })
    end

    params
  end

  # convert string keys to symbols
  def convert_activity_parameter_keys(activity)
    activity.parameters.transform_keys(&:to_sym)
  end
end
