# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    GroupCreateError = Class.new(StandardError)
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute # rubocop:disable Metrics/AbcSize
      group = Group.new(params.merge(owner: current_user))

      if group.parent&.owners&.exclude?(current_user) && group.parent&.owner != current_user
        raise GroupCreateError, 'You do not have permission to create a group under this namespace'
      end

      group.save

      Members::CreateService.new(current_user, group, {
                                   user: current_user,
                                   access_level: Member::AccessLevel::OWNER
                                 }).execute

      group
    rescue Groups::CreateService::GroupCreateError => e
      group.errors.add(:base, e.message)
      false
    end
  end
end
