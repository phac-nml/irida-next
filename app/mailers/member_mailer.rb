# frozen_string_literal: true

# Member Mailer
class MemberMailer < ApplicationMailer
  # include Roadie::Rails::Automatic

  def access_inform_user_email(member, access)
    subject = if access == 'granted'
                t(:'.access_granted_subject', type: member.namespace.type, id: member.namespace.id)
              elsif access == 'revoked'
                t(:'.access_revoked_subject', type: member.namespace.type, id: member.namespace.id)
              else
                t(:'.access_changed_subject', type: member.namespace.type, id: member.namespace.id)
              end
    mail(to: member.user.email, subject:)
  end

  def access_inform_manager_email(member, manager, access) # rubocop:disable Metrics/AbcSize
    subject = if access == 'granted'
                t(:'.access_granted_subject', first_name: member.user.first_name, last_name: member.user.last_name,
                                              type: member.namespace.type, id: member.namespace.id)
              elsif access == 'revoked'
                t(:'.access_revoked_subject', first_name: member.user.first_name, last_name: member.user.last_name,
                                              type: member.namespace.type, id: member.namespace.id)
              else
                t(:'.access_changed_subject', first_name: member.user.first_name, last_name: member.user.last_name,
                                              type: member.namespace.type, id: member.namespace.id)
              end
    mail(to: manager.user.email, subject:)
  end
end
