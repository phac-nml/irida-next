# frozen_string_literal: true

module Members
  # Service used to Delete Members
  class DestroyService < BaseService
    include MailerHelper
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
      return if Member.can_view?(member.user, namespace, true)

      MemberMailer.access_revoked_user_email(member, namespace).deliver_later
      MemberMailer.access_revoked_manager_email(member, manager_emails(member, namespace), namespace).deliver_later
    end
  end
end
