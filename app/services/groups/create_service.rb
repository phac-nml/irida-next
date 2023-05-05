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
      action_allowed_for_user(group.parent, :create?) unless group.parent.nil?

      group.save

      if group.parent.nil?
        Members::CreateService.new(current_user, group, {
                                     user: current_user,
                                     access_level: Member::AccessLevel::OWNER
                                   }).execute
      end

      group
    end
  end
end
