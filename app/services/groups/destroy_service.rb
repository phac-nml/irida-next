# frozen_string_literal: true

module Groups
  # Service used to Delete Groups
  class DestroyService < BaseService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      # TODO: Remove the current_user == group.owner once the project-members pr is merged in which
      # adds the owner as a group member
      if @group.group_members.find_by(user: current_user, access_level: Member::AccessLevel::OWNER) ||
         current_user == group.owner
        @group.destroy
      else
        @group.errors.add(:base, 'You are not authorized to delete this group.')
      end
    end
  end
end
