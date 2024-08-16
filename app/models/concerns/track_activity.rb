# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Model
    tracked owner: Current.user
  end

  def human_readable_activity(public_activities)
    activities = []
    public_activities.each do |activity|
      if activity.trackable_type == 'Namespace' && activity.key.include?('project_namespace')
        activities << project_activity(activity)
      elsif activity.trackable_type == 'Namespace' &&
            activity.key.include?('workflow_execution')
        activities << workflow_execution_activity(activity)
      elsif activity.trackable_type == 'Sample'
        activities << sample_activity(activity)
      elsif activity.trackable_type == 'Member'
        activities << member_activity(activity)
      elsif activity.trackable_type == 'NamespaceGroupLink'
        activities << namespace_group_link_activity(activity)
      end
    end

    activities
  end

  private

  def project_activity(activity)
    activity_trackable = activity_trackable(activity, Project)
    {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
      key: "activity.#{activity.key}",
      user: activity_creator(activity), name: activity_trackable.name,
      project_name: activity.parameters[:project_name],
      new_project_name: activity.parameters[:new_project_name],
      transferred_samples_ids: activity.parameters[:transferred_samples_ids],
      cloned_sample_ids: activity.parameters[:cloned_sample_ids],
      old_namespace: activity.parameters[:old_namespace],
      new_namespace: activity.parameters[:new_namespace],
      type: 'Namespace'
    }
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
      type: 'WorkflowExecution'
    }
  end

  def sample_activity(activity)
    activity_trackable = activity_trackable(activity, Sample)

    {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      sample: activity_trackable,
      type: 'Sample'
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
    activity.trackable.nil? ? relation.with_deleted.find(activity.trackable_id) : activity.trackable
  end
end
