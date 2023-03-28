# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      @member = Member.new(params.merge(created_by: current_user))
      @member.save

      @member
    end
  end
end
