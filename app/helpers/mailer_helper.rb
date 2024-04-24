# frozen_string_literal: true

# Helper for sending email notifications
module MailerHelper
  def user_emails(namespace)
    # user_memberships = Member.for_namespace_and_ancestors(namespace).not_expired
    user_memberships = Member.where(namespace:).not_expired
    users = User.where(id: user_memberships.select(:user_id)).distinct
    users.pluck(:email)
  end

  def manager_emails(namespace, member = nil)
    manager_memberships = Member.for_namespace_and_ancestors(namespace).not_expired
                                .where(access_level: Member::AccessLevel.manageable)
    managers = if member
                 User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: member.user.id)).distinct
               else
                 User.where(id: manager_memberships.select(:user_id)).distinct
               end
    managers.pluck(:email)
  end
end
