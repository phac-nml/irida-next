# frozen_string_literal: true

# Updates memberships for a group or project, so that the access level is ascending through its descendants.
class UpdateMembershipsJob < ApplicationJob
  queue_as :default

  def perform(membership_ids)
    memberships = Member.where(id: membership_ids)
    memberships.each(&:update_descendant_memberships)
  end
end
