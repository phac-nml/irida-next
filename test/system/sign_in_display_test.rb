# frozen_string_literal: true

require 'application_system_test_case'

class SignInDisplayTest < ApplicationSystemTestCase
  teardown do
    %w[developer saml azure_activedirectory_v2].each do |provider|
      Rails.configuration.auth_config["#{provider}_icon"] = nil
    end
  end

  test 'should display sign in with default text and icon' do
    visit new_user_session_path

    within %(div[class="grid gap-2"]) do
      assert_selector 'svg', count: 3 # Local Account does not use an icon
      assert_text I18n.t(:'devise.sessions.new_with_providers.local_button')
      %w[developer saml azure_activedirectory_v2].each do |provider|
        assert_text I18n.t(:'devise.sessions.new_with_providers.omniauth').to_s.sub!(
          '%{provider}', # rubocop:disable Style/FormatStringToken
          OmniAuth::Utils.camelize(provider)
        )
        assert_selector 'svg', class: "icon-#{provider}"
      end
    end
  end

  test 'should display sign in with custom text and icon' do
    custom_provider = 'azure_activedirectory_v2'
    custom_text = 'Tyrell Corporation'
    Rails.configuration.auth_config["#{custom_provider}_text"] = custom_text
    Rails.configuration.auth_config["#{custom_provider}_icon"] = '../test/fixtures/files/tyrell.svg'

    visit new_user_session_path

    within %(div[class="grid gap-2"]) do
      assert_text I18n.t(:'devise.sessions.new_with_providers.local_button')
      assert_text I18n.t(:'devise.sessions.new_with_providers.omniauth').to_s.sub!(
        '%{provider}', # rubocop:disable Style/FormatStringToken
        custom_text
      )
      assert_selector 'svg', class: "icon-#{custom_provider}_icon"
    end
  end
end
