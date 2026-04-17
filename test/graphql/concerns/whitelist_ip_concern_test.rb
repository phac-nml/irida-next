# frozen_string_literal: true

require 'test_helper'

class WhitelistIpConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @personal_access_token = personal_access_tokens(:john_doe_valid_pat)
    @basic_auth = Base64.encode64("#{users(:john_doe).email}:JQ2w5maQc4zgvC8GGMEp").strip
    @authorization_header = "Basic #{@basic_auth}"
  end

  test 'whitelist_ip adds new IP address to personal access token and sends email' do
    user = users(:john_doe)

    ip_address = '192.168.1.1'

    # Ensure the personal access token starts with no IP addresses
    assert_empty @personal_access_token.ip_addresses

    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => ip_address }

    assert_response :success

    # Verify that the IP address was added to the personal access token
    assert_includes @personal_access_token.reload.ip_addresses, ip_address

    assert_enqueued_emails 1 do
      PersonalAccessTokenMailer.new_ip_address_for_token(@personal_access_token, ip_address).deliver_later
    end

    perform_enqueued_jobs do
      PersonalAccessTokenMailer.new_ip_address_for_token(@personal_access_token, ip_address).deliver_later
    end

    # Verify that an email was sent to the user about the new IP address being added to their token
    email = ActionMailer::Base.deliveries.last
    assert_not_nil email, 'An email should have been sent'
    assert_equal [user.email], email.to, 'Email should be sent to the user associated with the personal access token'
    assert_equal I18n.t(:'mailers.personal_access_token_mailer.new_ip_address_for_token.subject',
                        token_name: @personal_access_token.name, locale: user.locale),
                 email.subject, 'Email subject should be correct'
    assert_match(
      /#{Regexp.escape(I18n.t(:'mailers.personal_access_token_mailer.new_ip_address_for_token.body_html', token_name: @personal_access_token.name, ip_address: ip_address, locale: user.locale))}/, email.body.to_s, 'Email body should contain the correct message' # rubocop:disable Layout/LineLength
    )
  end

  test 'whitelist_ip does not add IP address if it is already whitelisted' do
    ip_address = '192.168.1.1'
    ip_addresses = @personal_access_token.ip_addresses
    ip_addresses << ip_address
    @personal_access_token.update(ip_addresses: ip_addresses)

    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => ip_address }
    assert_response :success
    assert_includes @personal_access_token.reload.ip_addresses, ip_address

    assert_enqueued_emails 0
  end
end
