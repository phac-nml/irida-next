# frozen_string_literal: true

# Migration to move member trackable_type activities to namespace and add action to parameters
class MoveMemberActivitiesToNamespace < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    activity_keys = %w[member.create member.update member.destroy member.destroy_self]
    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      member = Member.with_deleted.find_by(id: activity.trackable_id)

      next if member.nil?

      ns = Namespace.with_deleted.find_by(id: member.namespace_id)

      # go to next activity as if the namespace doesn't exist
      # or is soft deleted, we cannot update it's activity. This may
      # leave activities with the trackable_type Member which are
      # no longer used. Leaving this activity as is since we can restore
      # a namespace and then would want its existing activity
      next if ns.deleted? || ns.nil?

      ns_type = if ns.type == Group.sti_name
                  'group'
                else
                  'namespaces_project_namespace'
                end

      if activity.key == 'member.create'
        activity.parameters[:action] = 'member_create'
        activity.key = "#{ns_type}.member.create"

      elsif (activity.key == 'member.destroy') || (activity.key == 'member.destroy_self')
        activity.parameters[:action] = 'member_destroy'

        destroy_key = if activity.key == 'member.destroy'
                        'destroy'
                      else
                        'destroy_self'
                      end

        activity.key = "#{ns_type}.member.#{destroy_key}"
      else
        activity.parameters[:action] = 'member_update'
        activity.key = "#{ns_type}.member.update"
      end

      activity.trackable_type = 'Namespace'
      activity.trackable_id = ns.id
      activity.save!
    end
  end
end
