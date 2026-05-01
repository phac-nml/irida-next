# frozen_string_literal: true

require 'test_helper'

class LastUsedIpConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @personal_access_token = personal_access_tokens(:john_doe_valid_pat)
    @basic_auth = Base64.encode64("#{users(:john_doe).email}:JQ2w5maQc4zgvC8GGMEp").strip
    @authorization_header = "Basic #{@basic_auth}"
  end

  test 'update_last_used_ips adds new IP address to personal access token and sends email' do
    user = users(:john_doe)

    ip_address = '192.168.1.1'

    # Ensure the personal access token starts with no IP addresses
    assert_empty @personal_access_token.last_used_ips

    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => ip_address }

    assert_response :success

    # Verify that the IP address was added to the personal access token
    assert_includes @personal_access_token.reload.last_used_ips, ip_address

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

  test 'update_last_used_ips does not add IP address if it is already in the list of last used ips' do
    ip_address = '192.168.1.1'
    ip_addresses = @personal_access_token.last_used_ips
    ip_addresses << ip_address
    @personal_access_token.update(last_used_ips: ip_addresses)

    assert_includes @personal_access_token.reload.last_used_ips, ip_address

    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => ip_address }
    assert_response :success

    count = @personal_access_token.reload.last_used_ips.count { |ip| ip == ip_address }
    assert_equal 1, count, 'IP address should not be added again if it is already in the list'

    assert_enqueued_emails 0
  end

  test 'update_last_used_ips returns early if personal access token is an integration token' do
    @personal_access_token.update(integration: true)
    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => '192.168.1.1' }

    assert_enqueued_emails 0
    assert_empty @personal_access_token.reload.last_used_ips
    assert_response :success
  end

  test 'update_last_used_ips returns early if IP address is nil' do
    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => nil }

    assert_enqueued_emails 0
    assert_empty @personal_access_token.reload.last_used_ips
    assert_response :success
  end

  test 'update_last_used_ips returns early if personal access token is nil' do
    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => '192.168.1.1' }

    assert_enqueued_emails 0
    assert_response :success
  end

  test 'update_last_used_ips only keeps track of the last 5 used ips' do
    ip_addresses = [IPAddr.new('192.2.2.0'), IPAddr.new('192.2.2.1'), IPAddr.new('192.2.2.2'), IPAddr.new('192.2.2.3'),
                    IPAddr.new('192.2.2.4')]

    @personal_access_token.update(last_used_ips: ip_addresses)

    first_ip_address = '192.2.2.0'
    new_ip_address = '192.2.2.5'

    assert_equal 5, @personal_access_token.last_used_ips.length

    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header, 'REMOTE_ADDR' => new_ip_address }

    assert_response :success

    assert_equal 5, @personal_access_token.last_used_ips.length

    # Verify that the IP address was added to the personal access token
    assert_includes @personal_access_token.reload.last_used_ips, new_ip_address

    assert_not_includes @personal_access_token.reload.last_used_ips, first_ip_address
  end
end
