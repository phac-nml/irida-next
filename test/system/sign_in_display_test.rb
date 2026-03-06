# frozen_string_literal: true

require 'application_system_test_case'

class SignInDisplayTest < ApplicationSystemTestCase
  setup do
    @test_file_relative_path = '../../../test/fixtures/files/tyrell.svg'
  end

  teardown do
    %w[developer saml entra_id].each do |provider|
      Rails.configuration.auth_config["#{provider}_text"] = nil
      Rails.configuration.auth_config["#{provider}_icon"] = nil
    end
  end

  test 'should display sign in with default text and icon' do
    visit new_user_session_path

    within %(div[class="grid gap-2"]) do
      assert_selector 'svg', count: 3 # Local Account does not use an icon
      assert_text I18n.t(:'devise.sessions.new.local_button')
      %w[developer saml entra_id].each do |provider|
        assert_text I18n.t(:'devise.sessions.new.omniauth').to_s.sub!(
          '%{provider}', # rubocop:disable Style/FormatStringToken
          OmniAuth::Utils.camelize(provider)
        )
        assert_selector 'svg', class: "icon-#{provider}"
      end
    end
  end

  test 'should display sign in with custom text and icon' do
    custom_provider = 'entra_id'
    custom_text = 'Tyrell Corporation'
    Rails.configuration.auth_config["#{custom_provider}_text"] = custom_text
    Rails.configuration.auth_config["#{custom_provider}_icon"] = @test_file_relative_path

    visit new_user_session_path

    within %(div[class="grid gap-2"]) do
      assert_text I18n.t(:'devise.sessions.new.local_button')
      assert_text I18n.t(:'devise.sessions.new.omniauth').to_s.sub!(
        '%{provider}', # rubocop:disable Style/FormatStringToken
        custom_text
      )
      assert_selector 'svg', class: "icon-#{custom_provider}_icon"
    end
  end

  test 'should display no authentication methods message when no providers and password authentication disabled' do
    old_omniauth_providers = User.omniauth_providers
    User.omniauth_providers = []
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false,
                                                               signup_enabled: false)

    visit new_user_session_path

    assert_text I18n.t(:'devise.sessions.new.no_configured_authentication_methods')
    User.omniauth_providers = old_omniauth_providers
  end

  test 'should not display local account option when password authentication disabled' do
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false)

    visit new_user_session_path

    assert_no_text I18n.t(:'devise.sessions.new.local_button')
  end
end
