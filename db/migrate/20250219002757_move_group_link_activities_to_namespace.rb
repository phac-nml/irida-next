# frozen_string_literal: true

# Migration to move group link activities to namespace activities
class MoveGroupLinkActivitiesToNamespace < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    activity_keys = %w[namespace_group_link.create namespace_group_link.destroy namespace_group_link.update]
    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      group_link = NamespaceGroupLink.with_deleted.find_by(id: activity.trackable_id)

      next if group_link.nil?

      group = Namespace.with_deleted.find_by(id: group_link&.group&.id)
      namespace = Namespace.with_deleted.find_by(id: group_link&.namespace&.id)

      next if namespace.nil? || group.nil?

      namespace_key = if namespace.group_namespace?
                        'group'
                      else
                        'namespaces_project_namespace'
                      end

      activity.key = "#{namespace_key}.#{activity.key}"
      activity.trackable_type = 'Namespace'
      activity.trackable_id = namespace.id
      activity.parameters[:group_name] = group_link.group.name
      activity.parameters[:group_puid] = group_link.group.puid
      activity.parameters[:namespace_name] = group_link.namespace.name
      activity.parameters[:namespace_puid] = group_link.namespace.puid
      activity.parameters[:namespace_type] = group_link.namespace.type.downcase

      action = if activity.key.include?('create')
                 'group_link_create'
               elsif activity.key.include?('destroy')
                 'group_link_destroy'
               else
                 'group_link_update'
               end

      activity.parameters[:action] = action
      activity.save!
    end
  end
end
