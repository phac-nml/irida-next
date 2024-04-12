# frozen_string_literal: true

module GroupLinks
  # Service used to Destroy NamespaceGroupLinks
  class GroupUnlinkService < BaseService
    attr_accessor :namespace_group_link

    def initialize(user, namespace_group_link, params = {})
      super(user, params)
      @namespace_group_link = namespace_group_link
    end

    def execute # rubocop:disable Metrics/AbcSize
      return if namespace_group_link.nil?

      authorize! namespace_group_link.namespace, to: :unlink_namespace_with_group?

      # TODO: move to callback
      manager_memberships = Member.where(namespace_id: namespace_group_link.group).not_expired
                                  .where(access_level: Member::AccessLevel.manageable)
      managers = User.where(id: manager_memberships.select(:user_id)).distinct
      manager_emails = managers.pluck(:email)
      memberships = Member.where(namespace_id: namespace_group_link.group).not_expired

      memberships.each do |member|
        next if Member.can_view?(member.user, namespace_group_link.namespace, false) # TODO: change to true

        MemberMailer.access_email(member, manager_emails, 'revoked', namespace_group_link.namespace).deliver_later
      end

      namespace_group_link.destroy
    end
  end
end
