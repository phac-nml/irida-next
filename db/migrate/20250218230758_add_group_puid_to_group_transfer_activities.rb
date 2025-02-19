# frozen_string_literal: true

# Migration to add transferred group puid to group transfer activities
class AddGroupPuidToGroupTransferActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[group.transfer_out group.transfer_in group.transfer_in_no_exisiting_namespace]

    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      transferred_group = Group.with_deleted.find_by(id: activity.parameters[:transferred_group_id])

      unless transferred_group.nil?
        activity.parameters[:transferred_group_puid] = transferred_group.puid
        activity.save
      end
    end
  end
end
