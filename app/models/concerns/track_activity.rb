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
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity), name: activity.trackable.name)
    }
  end

  def sample_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      sample_name: activity.trackable.name)
    }
  end

  def attachment_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      sample_name: activity.trackable.attachable.name)
    }
  end

  def member_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      namespace_type: activity.trackable.namespace.type.downcase,
                                                      name: activity.trackable.namespace.name,
                                                      member: activity.trackable.user.email)
    }
  end

  def namespace_group_link_activity(activity)
    {
      created_at: activity.created_at,
      description: I18n.t("activity.#{activity.key}", user: activity_creator(activity),
                                                      namespace_type: activity.trackable.namespace.type.downcase,
                                                      name: activity.trackable.namespace.name,
                                                      group_name: activity.trackable.group.name)
    }
  end

  def activity_creator(activity)
    activity.owner.nil? ? I18n.t('activerecord.concerns.track_activity.system') : activity.owner.email
  end
end
