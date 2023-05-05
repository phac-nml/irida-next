# frozen_string_literal: true

module Groups
  # Service used to Delete Groups
  class DestroyService < BaseService
    GroupDestroyError = Class.new(StandardError)
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      action_allowed_for_user(group, :destroy?)
      group.destroy
    end
  end
end
