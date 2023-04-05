# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    GroupCreateError = Class.new(StandardError)
    attr_accessor :group

    def initialize(user = nil, params = {})
      super(user, params)
      @group = Group.new(params.merge(owner: current_user))
    end

    def execute
      unless allowed_to_modify_group?(group)
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
      group
    end
  end
end
