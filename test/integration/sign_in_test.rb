# frozen_string_literal: true

require 'test_helper'

class SignInTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
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
    begin
      User.omniauth_providers = []
      Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false,
                                                                 signup_enabled: false)

      get new_user_session_path

      assert_response :success
      assert_select 'div[role="alert"]',
                    text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.no_configured_authentication_methods'))}/
    ensure
      User.omniauth_providers = old_omniauth_providers
    end
  end

  test 'should not display local account option when password authentication disabled' do
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false)

    get new_user_session_path

    assert_response :success
    assert_select 'a', text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.local_button'))}/, count: 0
  end

  test 'should display sign in with local account' do
    get new_user_session_path

    assert_response :success
    assert_select 'h1', text: I18n.t(:'devise.layout.title'), count: 1

    get new_user_session_path(local: true)

    assert_response :success
    assert_select 'body', text: /#{Regexp.escape(I18n.t(:'devise.sessions.new.return_button'))}/
    assert_equal '/users/sign_in?local=true', request.fullpath
  end

  test 'should display error during with local account' do
    user = users(:john_doe)

    get new_user_session_path

    assert_response :success
    assert_select 'h1', text: I18n.t(:'devise.layout.title'), count: 1

    get new_user_session_path(local: true)

    assert_response :success
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'invalid password'
      },
      local: true
    }

    assert_response :unprocessable_content
    assert_select 'body', text: /Invalid Email or password/
    assert_select 'form[action="/users/sign_in"]' do
      assert_select 'label', text: /Email/, count: 1
      assert_select 'label', text: /Password/, count: 1
    end
    assert_equal '/users/sign_in', request.path
  end

  test 'should set Clear-Site-Data header on sign_out' do
    sign_in users(:john_doe)

    delete destroy_user_session_path

    assert_equal '"cookies", "storage", "cache"', response.headers['Clear-Site-Data']
  end

  test 'should update the user locale when locale param is present on sign in' do
    assert_changes -> { users(:john_doe).reload.locale }, from: 'en', to: 'fr' do
      post user_session_path, params: {
        user: {
          email: users(:john_doe).email,
          password: 'password1'
        },
        locale: 'fr'
      }
    end
  end

  test 'should not update the user locale when locale param is not present on sign in' do
    user = users(:john_doe)
    original_locale = user.locale

    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password1'
      }
    }

    assert_response :see_other
    assert_equal original_locale, user.reload.locale
  end

  test 'should render not_authorized when password authentication is disabled and user attempts to sign in' do
    Irida::CurrentSettings.current_application_settings.update(password_authentication_enabled: false)
    user = users(:john_doe)

    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password1'
      }
    }

    assert_response :forbidden
    assert_select 'h1', text: I18n.t(:'application.errors.access_denied')
  end

  test 'should include locale param in links when I18n.locale is not default locale' do
    I18n.with_locale(:fr) do
      get new_user_session_path

      assert_response :success
      # Check that the return button includes the locale parameter
      assert_select 'a[href*="locale=fr"]'
    end
  end

  test 'should render shared links partial when no button based providers are enabled' do
    old_omniauth_providers = User.omniauth_providers
    User.omniauth_providers = []

    get new_user_session_path

    assert_response :success
    # The shared/links partial renders the forgot password link
    assert_select 'a', text: /#{Regexp.escape(I18n.t(:'devise.shared.links.forgot_password_link'))}/

    User.omniauth_providers = old_omniauth_providers
  end
end
