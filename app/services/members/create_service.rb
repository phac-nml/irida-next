# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute
      action_allowed_for_user(namespace, :allowed_to_modify_members?)

      if Member.user_has_namespace_maintainer_access?(current_user,
                                                      namespace) &&
         (member.access_level > Member::AccessLevel::MAINTAINER)
        raise MemberCreateError, 'A maintainer can only add user\'s upto the Maintainer role'
      end

      member.save
      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end
  end
end
