# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/member_mailer
class MemberMailerPreview < ActionMailer::Preview
  def access_granted_to_group_email
    setup
    MemberMailer.access_granted_email(@member, @manager_emails, @namespace)
  end

  def access_granted_to_project_email
    setup
    MemberMailer.access_granted_email(@member, @manager_emails, @namespace)
  end

  def access_revoked_from_group_email
    setup
    MemberMailer.access_revoked_email(@member, @manager_emails, @namespace)
  end

  def access_revoked_from_project_email
    setup
    MemberMailer.access_revoked_email(@member, @manager_emails, @namespace)
  end

  private

  def setup
    @member = Member.first
    @namespace = @member.namespace
    manager_memberships = Member.for_namespace_and_ancestors(@namespace).not_expired
                                .where(access_level: Member::AccessLevel.manageable)
    managers = User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: @member.user.id)).distinct
    @manager_emails = managers.pluck(:email)
  end
end
