# frozen_string_literal: true

module Members
  # Service used to Update Members
  class DestroyService < BaseService
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize
      # TODO: Remove the current_user == namespace.owner once the project-members pr is merged in which adds the creator
      # as a group/project member.
      if ((current_user != member.user) &&
         namespace.owners.find_by(id: current_user.id)) ||
         current_user == namespace.owner
        member.destroy
      elsif current_user == member.user
        member.errors.add(:base, "You cannot remove yourself from the #{namespace.type.downcase}")
      else
        member.errors.add(:base, 'You are not authorized to remove this member')
      end
    end

    def members
      if member.type == 'GroupMember'
        namespace.group_members
      else
        namespace.project_members
      end
    end
  end
end
