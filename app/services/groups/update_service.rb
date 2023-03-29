# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      group.update(params)
    end
  end
end
