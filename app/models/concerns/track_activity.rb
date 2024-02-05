# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Model
    tracked owner: proc { |controller, _model| controller&.current_user || nil }
  end

  def formatted_activities(activities)
    res = []
    activities.each do |activity|
      if activity.trackable_type == 'Namespace' && activity.key.include?('namespaces_project_namespace')
        res << project_activity(activity)
      elsif activity.trackable_type == 'Sample'
        res << sample_activity(activity)
      elsif activity.trackable_type == 'Member'
        res << member_activity(activity)
      elsif activity.trackable_type == 'NamespaceGroupLink'
        res << namespace_group_link_activity(activity)
      end
    end

    res
  end

  private

  def project_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity.owner.email, name: activity.trackable.name)
    }
  end

  def sample_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity.owner.email, sample_name: activity.trackable.name)
    }
  end

  def attachment_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity.owner.email,
                                                      project_name: activity.trackable.project.name,
                                                      sample_name: activity.trackable.name)
    }
  end

  def member_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity.owner.email,
                                                      namespace_type: activity.trackable.namespace.type.downcase,
                                                      name: activity.trackable.namespace.name,
                                                      member: activity.trackable.user.email)
    }
  end

  def namespace_group_link_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity.owner.email,
                                                      namespace_type: activity.trackable.namespace.type.downcase,
                                                      name: activity.trackable.namespace.name,
                                                      group_name: activity.trackable.group.name)
    }
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
