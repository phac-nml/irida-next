# frozen_string_literal: true

# Personal Access Token Mailer
class PersonalAccessTokenMailer < ApplicationMailer
  def complete_user_email(personal_access_token, ip_address)
    @personal_access_token = personal_access_token
    @ip_address = ip_address
    I18n.with_locale(@personal_access_token.user.locale) do
      mail(to: @personal_access_token.user.email,
           subject: t(:'mailers.personal_access_token_mailer.new_ip_address_for_token.subject',
                      token_name: @personal_access_token.name))
    end
  end
end
