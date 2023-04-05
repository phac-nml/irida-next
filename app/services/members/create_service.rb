# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
      @member = Member.new(params.merge(created_by: current_user, namespace:, type: member_type))
    end

    def execute
      unless allowed_to_modify_members_in_namespace?(namespace)
        raise MemberCreateError,
              I18n.t('services.members.create.no_permission',
                     namespace_type: namespace.type.downcase)
      end

      member.save
      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end

    def member_type
      "#{namespace.type}Member"
    end
  end
end
