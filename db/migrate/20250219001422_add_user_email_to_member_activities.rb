# frozen_string_literal: true

# Migration to add member email to member activities
class AddUserEmailToMemberActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[member.create member.update member.destroy member.destroy_self]
    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      member = Member.with_deleted.find_by(id: activity.trackable_id)

      next if member.nil?

      activity.parameters[:member_email] = if member.user.nil?
                                             'deleted_user'
                                           else
                                             member.user.email
                                           end
      activity.save
    end
  end
end
