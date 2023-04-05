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

    def execute # rubocop:disable Metrics/AbcSize
      unless (group.parent.nil? && group.owner == current_user) || group.owners.include?(current_user) ||
             (group.parent.group_namespace? && group.parent.owners.include?(current_user))
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
