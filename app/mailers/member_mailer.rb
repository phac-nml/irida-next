# frozen_string_literal: true

# Member Mailer
class MemberMailer < ApplicationMailer
  def access_email(member, manager_emails, access, namespace) # rubocop:disable Metrics/AbcSize
    subject = if access == 'granted'
                t(:'.access_granted_subject', first_name: member.user.first_name.capitalize,
                                              last_name: member.user.last_name.capitalize,
                                              type: namespace.type,
                                              id: namespace.id)
              elsif access == 'revoked'
                t(:'.access_revoked_subject', first_name: member.user.first_name.capitalize,
                                              last_name: member.user.last_name.capitalize,
                                              type: namespace.type,
                                              id: namespace.id)
              end
    mail(to: member.user.email, bcc: manager_emails, subject:)
  end
end
