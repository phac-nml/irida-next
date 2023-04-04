# frozen_string_literal: true

module Members
  # Service used to Update Members
  class UpdateService < BaseService
    MemberUpdateError = Class.new(StandardError)
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      # TODO: Update params to only keep required values
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize
      unless current_user != member.user
        raise MemberUpdateError, I18n.t('services.members.update.cannot_update_self',
                                        namespace_type: namespace.type.downcase)
      end

      unless allowed_to_modify_members_in_namespace?(namespace)
        raise MemberUpdateError,
              I18n.t('services.members.update.no_permission', namespace_type: namespace.type.downcase)
      end

      member.update(params)

      raise MemberUpdateError, member.errors.full_messages.first if member.errors
    rescue Members::UpdateService::MemberUpdateError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
