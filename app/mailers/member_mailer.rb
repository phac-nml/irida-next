# frozen_string_literal: true

# Member Mailer
class MemberMailer < ApplicationMailer
  def access_granted_email(member, manager_emails, namespace)
    @member = member
    @namespace = namespace
    subject = t(:'mailers.member_mailer.access_granted_email.subject',
                first_name: @member.user.first_name.capitalize,
                last_name: @member.user.last_name.capitalize,
                type: @namespace.type,
                name: @namespace.name)
    mail(to: @member.user.email, bcc: manager_emails, subject:)
  end

  def access_revoked_email(member, manager_emails, namespace)
    @member = member
    @namespace = namespace
    subject = t(:'mailers.member_mailer.access_revoked_email.subject',
                first_name: @member.user.first_name.capitalize,
                last_name: @member.user.last_name.capitalize,
                type: @namespace.type,
                name: @namespace.name)
    mail(to: @member.user.email, bcc: manager_emails, subject:)
  end
end
