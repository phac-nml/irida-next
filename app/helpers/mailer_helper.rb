# frozen_string_literal: true

# Helper for sending email notifications
module MailerHelper
  def manager_emails(member, namespace)
    manager_memberships = Member.for_namespace_and_ancestors(namespace).not_expired
                                .where(access_level: Member::AccessLevel.manageable)
    managers = User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: member.user.id)).distinct
    managers.pluck(:email)
  end
end
