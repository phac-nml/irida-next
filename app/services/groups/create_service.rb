# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      @group = Group.new(params.merge(owner: current_user))
      @group.save

      Members::CreateService.new(current_user, {
                                   user: current_user, namespace: @group,
                                   access_level: Member::AccessLevel::OWNER,
                                   type: 'GroupMember'
                                 }).execute

      @group
    end
  end
end
