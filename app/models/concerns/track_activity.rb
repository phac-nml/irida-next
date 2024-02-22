# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Model
    tracked owner: proc { |controller, _model| controller&.current_user || nil }
  end

  def human_readable_activity(public_activities) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    activities = []
    public_activities.each do |activity|
      if activity.trackable_type == 'Namespace' && activity.key.include?('namespaces_project_namespace')
        activities << project_activity(activity)
      elsif activity.trackable_type == 'Sample'
        activities << sample_activity(activity)
      elsif activity.trackable_type == 'Attachment'
        activities << attachment_activity(activity)
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
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity), name: activity_trackable.name)
    }
  end

  def sample_activity(activity)
    activity_trackable = activity_trackable(activity, Sample)

    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      sample_name: activity_trackable.name)
    }
  end

  def attachment_activity(activity)
    activity_trackable = activity_trackable(activity, Attachment)

    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      sample_name: activity_trackable.attachable.name)
    }
  end

  def member_activity(activity)
    activity_trackable = activity_trackable(activity, Member)

    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      namespace_type: activity_trackable.namespace.type.downcase,
                                                      name: activity_trackable.namespace.name,
                                                      member: activity_trackable.user.email)
    }
  end

  def namespace_group_link_activity(activity)
    activity_trackable = activity_trackable(activity, NamespaceGroupLink)

    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      namespace_type: activity_trackable.namespace.type.downcase,
                                                      name: activity_trackable.namespace.name,
                                                      group_name: activity_trackable.group.name)
    }
  end

  def activity_creator(activity)
    activity.owner.nil? ? I18n.t('activerecord.concerns.track_activity.system') : activity.owner.email
  end

  def activity_trackable(activity, relation)
    activity.trackable.nil? ? relation.with_deleted.find(activity.trackable_id) : activity.trackable
  end
end
