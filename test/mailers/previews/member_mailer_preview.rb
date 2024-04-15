# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/member_mailer
class MemberMailerPreview < ActionMailer::Preview
  def granted_access_email
    setup
    MemberMailer.access_email(@member, @manager_emails, 'granted', @namespace)
  end

  def revoked_access_email
    setup
    MemberMailer.access_email(@member, @manager_emails, 'revoked', @namespace)
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
