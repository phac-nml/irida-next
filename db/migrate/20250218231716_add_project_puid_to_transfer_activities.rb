# frozen_string_literal: true

# Migration to add project puid to group project transfer activities
class AddProjectPuidToTransferActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[namespaces_project_namespace.transfer group.projects.transfer_out group.projects.transfer_in]

    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      transferred_project = Project.with_deleted.find_by(id: activity.parameters[:project_id])

      next if transferred_project.nil?

      ns = Namespace.with_deleted.find_by(id: transferred_project.namespace_id)

      unless ns.nil?
        activity.parameters[:project_puid] = ns.puid
        activity.save
      end
    end
  end
end
