# frozen_string_literal: true

# Member Mailer
class MemberMailer < ApplicationMailer
  def access_granted_user_email(member, namespace)
    @member = member
    @namespace = namespace
    I18n.with_locale(@member.user.locale) do
      subject = t(:'mailers.member_mailer.access_granted_user_email.subject',
                  type: @namespace.type,
                  name: @namespace.name)
      mail(to: @member.user.email, subject:)
    end
  end

  def access_revoked_user_email(member, namespace)
    @member = member
    @namespace = namespace
    I18n.with_locale(@member.user.locale) do
      subject = t(:'mailers.member_mailer.access_revoked_user_email.subject',
                  type: @namespace.type,
                  name: @namespace.name)
      mail(to: @member.user.email, subject:)
    end
  end

  def access_granted_manager_email(member, manager_emails, namespace, locale)
    @member = member
    @namespace = namespace
    I18n.with_locale(locale) do
      subject = t(:'mailers.member_mailer.access_granted_manager_email.subject',
                  first_name: @member.user.first_name.capitalize,
                  last_name: @member.user.last_name.capitalize,
                  email: @member.user.email,
                  type: @namespace.type,
                  name: @namespace.name)
      mail(bcc: manager_emails, subject:)
    end
  end

  def access_revoked_manager_email(member, manager_emails, namespace, locale)
    @member = member
    @namespace = namespace
    I18n.with_locale(locale) do
      subject = t(:'mailers.member_mailer.access_revoked_manager_email.subject',
                  first_name: @member.user.first_name.capitalize,
                  last_name: @member.user.last_name.capitalize,
                  email: @member.user.email,
                  type: @namespace.type,
                  name: @namespace.name)
      mail(bcc: manager_emails, subject:)
    end
  end
end
