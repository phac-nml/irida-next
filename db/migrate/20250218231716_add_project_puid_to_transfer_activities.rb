# frozen_string_literal: true

# Migration to add project puid to group project transfer activities
class AddProjectPuidToTransferActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[namespaces_project_namespace.transfer group.projects.transfer_out group.projects.transfer_in]

    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      transferred_project = Project.find_by(id: activity.parameters[:project_id])

      unless transferred_project.nil?
        activity.parameters[:project_puid] = transferred_project.namespace.puid
        activity.save
      end
    end
  end
end
