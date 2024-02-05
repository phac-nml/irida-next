# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity
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
end
