# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Model
    tracked owner: proc { Current.user }
  end

  def human_readable_activity(public_activities) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

  def project_activity(activity) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_trackable = activity_trackable(activity, Project)

    base = {
      created_at: activity.created_at.strftime(
        I18n.t('time.formats.abbreviated')
      ),
      key: "activity.#{activity.key}_html",
      user: activity_creator(activity),
      name: activity_trackable.name,
      type: 'Namespace',
      action: activity.parameters[:action].presence || 'default'
    }

    return base if activity.parameters[:action].blank?

    if activity.parameters[:action] == 'project_namespace_transfer'
      base.merge!({
                    old_namespace: activity.parameters[:old_namespace]
                  })
    end

    unless activity.parameters[:action] == 'sample_transfer' || activity.parameters[:action] == 'sample_clone'
      return base
    end

    base.merge!({
                  source_project: get_object_by_id(activity.parameters[:source_project], Project),
                  target_project: get_object_by_id(activity.parameters[:target_project], Project)
                })

    base
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
    activity.trackable.nil? ? get_object_by_id(activity.trackable_id, relation) : activity.trackable
  end

  def get_object_by_id(identifier, relation)
    relation.with_deleted.find_by(id: identifier)
  end
end
