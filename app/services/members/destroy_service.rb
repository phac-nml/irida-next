# frozen_string_literal: true

module Members
  # Service used to Delete Members
  class DestroyService < BaseService
    MemberDestroyError = Class.new(StandardError)
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize
      if current_user != member.user
        authorize! @namespace, to: :destroy_member?

        unless Member.namespace_owners_include_user?(current_user, namespace) ||
               (Member.user_has_namespace_maintainer_access?(current_user,
                                                             namespace) &&
                                                             member.access_level <= Member::AccessLevel::MAINTAINER)
          raise MemberDestroyError,
                I18n.t('services.members.destroy.role_not_allowed')
        end
      end

      send_emails if member.destroy
    rescue Members::DestroyService::MemberDestroyError => e
      member.errors.add(:base, e.message)
      false
    end

    private

    def send_emails
      return unless member.deleted?

      access = 'revoked'
      MemberMailer.access_inform_user_email(member, access).deliver_later
      managers = Member.for_namespace_and_ancestors(member.namespace).not_expired
                       .where(access_level: Member::AccessLevel.manageable)
      managers.each do |manager|
        MemberMailer.access_inform_manager_email(member, manager, access).deliver_later
      end
    end
  end
end
