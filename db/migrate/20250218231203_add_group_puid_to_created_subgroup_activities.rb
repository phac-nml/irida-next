# frozen_string_literal: true

# Migration to add group puid to subgroup create activities
class AddGroupPuidToCreatedSubgroupActivities < ActiveRecord::Migration[7.2]
  def change
    activities = PublicActivity::Activity.where(key: 'group.subgroups.create')

    activities.each do |activity|
      created_group = Group.with_deleted.find_by(id: activity.parameters[:created_group_id])

      unless created_group.nil?
        activity.parameters[:created_group_puid] = created_group.puid
        activity.save
      end
    end
  end
end
