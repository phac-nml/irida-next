# frozen_string_literal: true

# Group Link Mailer
class GroupLinkMailer < ApplicationMailer
  def access_granted_user_email(user_emails, group, namespace, locale)
    @group = group
    @namespace = namespace
    subject = t(:'mailers.group_link_mailer.access_granted_user_email.subject',
                group_name: @group.name,
                namespace_type: @namespace.type,
                namespace_name: @namespace.name)
    I18n.with_locale(locale) do
      mail(bcc: user_emails, subject:)
    end
  end

  def access_revoked_user_email(user_emails, group, namespace, locale)
    @group = group
    @namespace = namespace
    subject = t(:'mailers.group_link_mailer.access_revoked_user_email.subject',
                group_name: @group.name,
                namespace_type: @namespace.type,
                namespace_name: @namespace.name)
    I18n.with_locale(locale) do
      mail(bcc: user_emails, subject:)
    end
  end

  def access_granted_manager_email(manager_emails, group, namespace, locale)
    @group = group
    @namespace = namespace
    subject = t(:'mailers.group_link_mailer.access_granted_manager_email.subject',
                group_name: @group.name,
                namespace_type: @namespace.type,
                namespace_name: @namespace.name)
    I18n.with_locale(locale) do
      mail(bcc: manager_emails, subject:)
    end
  end

  def access_revoked_manager_email(manager_emails, group, namespace, locale)
    @group = group
    @namespace = namespace
    subject = t(:'mailers.group_link_mailer.access_revoked_manager_email.subject',
                group_name: @group.name,
                namespace_type: @namespace.type,
                namespace_name: @namespace.name)
    I18n.with_locale(locale) do
      mail(bcc: manager_emails, subject:)
    end
  end
end
