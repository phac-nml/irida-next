# frozen_string_literal: true

module Members
  # Service used to Update Members
  class UpdateService < BaseService
    MemberUpdateError = Class.new(StandardError)
    attr_accessor :member

    def initialize(member, user = nil, params = {})
      # TODO: Update params to only keep required values
      super(user, params)
      @member = member
    end

    def execute # rubocop:disable Metrics/AbcSize
      if current_user == member.user
        raise MemberDestroyError, I18n.t('services.members.update.cannot_update_self',
                                         namespace_type: namespace.type.downcase)
      end

      if namespace.owners.exclude?(current_user)
        raise MemberDestroyError,
              I18n.t('services.members.update.no_permission', namespace_type: namespace.type.downcase)
      end

      member.destroy
    rescue Members::DestroyService::MemberDestroyError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
