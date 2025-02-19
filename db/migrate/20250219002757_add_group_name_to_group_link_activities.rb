# frozen_string_literal: true

# Migration to add group name to namespace group link activities
class AddGroupNameToGroupLinkActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[namespace_group_link.create namespace_group_link.destroy namespace_group_link.update]
    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      group_link = NamespaceGroupLink.with_deleted.find_by(id: activity.trackable_id)

      unless group_link.nil?
        activity.parameters['group_name'] = group_link.group.name
        activity.save
      end
    end
  end
end
