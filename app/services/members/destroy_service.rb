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

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if current_user != member.user
        authorize! @namespace, to: :destroy_member?

        unless (Member.effective_access_level(namespace, current_user) == Member::AccessLevel::OWNER) ||
               (Member.effective_access_level(namespace, current_user) == Member::AccessLevel::MAINTAINER &&
                                                             (member.access_level <= Member::AccessLevel::MAINTAINER))
          raise MemberDestroyError,
                I18n.t('services.members.destroy.role_not_allowed')
        end
      end

      member.destroy

      if member.deleted?
        send_emails
        create_activities
      end
    rescue Members::DestroyService::MemberDestroyError => e
      member.errors.add(:base, e.message)
      false
    end

    private

    def send_emails
      return if Member.effective_access_level(namespace,
                                              member.user) > Member::AccessLevel::NO_ACCESS

      MemberMailer.access_revoked_user_email(member, namespace).deliver_later
    end

    def create_activities # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      namespace_key = if member.namespace.group_namespace?
                        'group'
                      else
                        'namespaces_project_namespace'
                      end

      if current_user == member.user
        member.namespace.create_activity key: "#{namespace_key}.member.destroy_self", owner: current_user, parameters: {
          member_email: member.user.email,
          action: 'member_destroy'
        }
      else
        member.namespace.create_activity key: "#{namespace_key}.member.destroy", owner: current_user, parameters: {
          member_email: member.user.email,
          action: 'member_destroy'
        }
      end
    end
  end
end
