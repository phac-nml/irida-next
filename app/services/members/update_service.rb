# frozen_string_literal: true

module Members
  # Service used to Update Members
  class UpdateService < BaseService
    attr_accessor :member

    def initialize(member, user = nil, params = {})
      # TODO: Update params to only keep required values
      super(user, params)
      @member = member
    end

    def execute
      member.update(params)
    end
  end
end
