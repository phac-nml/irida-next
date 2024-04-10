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

    def send_emails # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return unless member.deleted?

      linked_memberships = Member.for_namespace_and_ancestors(member.namespace.parent).not_expired
                                 .where(user: member.user)
      same_access_linked_memberships = linked_memberships.and(Member.where(access_level: member.access_level))

      return unless same_access_linked_memberships.empty?

      access = if linked_memberships.empty?
                 'revoked'
               else
                 'changed'
               end

      MemberMailer.access_inform_user_email(member, access).deliver_later
      manager_memberships = Member.for_namespace_and_ancestors(member.namespace).not_expired
                                  .where(access_level: Member::AccessLevel.manageable)
      managers = User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: member.user.id))
                     .distinct
      managers.each do |manager|
        MemberMailer.access_inform_manager_email(member, manager, access).deliver_later
      end
    end
  end
end
