# frozen_string_literal: true

require 'test_helper'

class SignInTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    @test_file_relative_path = '../../../test/fixtures/files/tyrell.svg'
    Warden.test_mode!
    # Reload routes to ensure OmniAuth routes are loaded
    Rails.application.reload_routes!
  end

  teardown do
    Warden.test_reset!
    %w[developer saml entra_id].each do |provider|
      Rails.configuration.auth_config["#{provider}_text"] = nil
      Rails.configuration.auth_config["#{provider}_icon"] = nil
    end
  end

  test 'should display sign in with default text and icon' do
    get new_user_session_path

    assert_response :success
    # Local Account button
    assert_select 'a', text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.local_button'))}/
    # Omniauth provider buttons with default text
    %w[developer saml entra_id].each do |provider|
      expected_text = I18n.t(:'devise.sessions.new.omniauth').to_s.sub!(
        '%{provider}', # rubocop:disable Style/FormatStringToken
        OmniAuth::Utils.camelize(provider)
      )
      assert_select 'button', text: /#{Regexp.escape(expected_text)}/
      assert_select "svg.icon-#{provider}"
    end
  end

  test 'should display sign in with custom text and icon' do
    custom_provider = 'entra_id'
    custom_text = 'Tyrell Corporation'
    Rails.configuration.auth_config["#{custom_provider}_text"] = custom_text
    Rails.configuration.auth_config["#{custom_provider}_icon"] = @test_file_relative_path

    get new_user_session_path

    assert_response :success
    # Local Account button
    assert_select 'a', text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.local_button'))}/
    # Custom text for entra_id button
    expected_text = I18n.t(:'devise.sessions.new.omniauth').to_s.sub!(
      '%{provider}', # rubocop:disable Style/FormatStringToken
      custom_text
    )
    assert_select 'button', text: /#{Regexp.escape(expected_text)}/
    # Custom icon for entra_id
    assert_select "svg.icon-#{custom_provider}_icon"
  end

  test 'should display no authentication methods message when no providers and password authentication disabled' do
    old_omniauth_providers = User.omniauth_providers
    User.omniauth_providers = []
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false,
                                                               signup_enabled: false)

    get new_user_session_path

    assert_response :success
    assert_select 'div[role="alert"]',
                  text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.no_configured_authentication_methods'))}/
    User.omniauth_providers = old_omniauth_providers
  end

  test 'should not display local account option when password authentication disabled' do
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false)

    get new_user_session_path

    assert_response :success
    assert_select 'a', text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.local_button'))}/, count: 0
  end
end
