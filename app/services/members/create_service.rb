# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    attr_accessor :namespace

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
    end

    def execute
      @member = Member.new(params.merge(created_by: current_user, namespace:, type: member_type))
      @member.save

      @member
    end

    def member_type
      "#{namespace.type}Member"
    end
  end
end
