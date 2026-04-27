# frozen_string_literal: true

require 'test_helper'

class PersonalAccessTokenMailerTest < ActionMailer::TestCase
  def test_localized_new_ip_address_for_token_email # rubocop:disable Metrics/AbcSize
    I18n.available_locales.each do |locale|
      personal_access_token = personal_access_tokens(:john_doe_valid_pat)
      personal_access_token.user.locale = locale
      email = PersonalAccessTokenMailer.new_ip_address_for_token(personal_access_token, '192.168.1.1')
      assert_equal [personal_access_token.user.email], email.to
      assert_equal I18n.t(:'mailers.personal_access_token_mailer.new_ip_address_for_token.subject',
                          token_name: personal_access_token.name,
                          locale:), email.subject
      message = I18n.t(:'mailers.personal_access_token_mailer.new_ip_address_for_token.body_html',
                       token_name: personal_access_token.name, ip_address: '192.168.1.1', locale:)

      assert_match(/#{Regexp.escape(message)}/, email.body.to_s)
    end
  end
end
