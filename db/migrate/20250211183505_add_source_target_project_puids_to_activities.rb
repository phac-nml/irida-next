# frozen_string_literal: true

# Migration to add source and target project puids to clone and transfer activities
class AddSourceTargetProjectPuidsToActivities < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_keys = %w[namespaces_project_namespace.samples.clone
                       namespaces_project_namespace.samples.cloned_from
                       namespaces_project_namespace.samples.transfer
                       namespaces_project_namespace.samples.transferred_from]

    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      if activity.parameters.key?(:target_project)
        ns_id = Project.with_deleted.find_by(id: activity.parameters[:target_project]).namespace_id
        puid_key = :target_project_puid
      else
        ns_id = Project.with_deleted.find_by(id: activity.parameters[:source_project]).namespace_id
        puid_key = :source_project_puid
      end

      ns = Namespace.with_deleted.find_by(id: ns_id)
      activity.parameters[puid_key] = ns.puid
      activity.save
    end
  end
end
