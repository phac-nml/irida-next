# frozen_string_literal: true

require 'omniauth_integration_test_case'

class OmniauthCallbacksDeveloperTest < OmniauthIntegrationTestCase
  test 'get first user or create' do
    valid_developer_login_setup
    assert_difference 'User.count' do
      get '/users/auth/developer/callback'
    end

    assert session.key? 'warden.user.user.key'
    assert_equal session['warden.user.user.key'][0][0], User.last.id
    assert_redirected_to root_path
  end

  test 'invalid get first user or create' do
    invalid_developer_login_setup
    assert_no_changes 'User.count' do
      get '/users/auth/developer/callback'
    end

    assert_equal :invalid_credentials, request.env['omniauth.error.type']
    assert_not session.key? 'warden.user.user.key'
    assert_redirected_to new_user_session_path
  end
end

class OmniauthCallbacksAzureTest < OmniauthIntegrationTestCase
  test 'get first user or create' do
    valid_azure_login_setup
    assert_difference 'User.count' do
      get '/users/auth/entra_id/callback'
    end

    assert session.key? 'warden.user.user.key'
    assert_equal session['warden.user.user.key'][0][0], User.last.id
    assert_redirected_to root_path
  end

  test 'invalid get first user or create' do
    invalid_azure_login_setup
    assert_no_changes 'User.count' do
      get '/users/auth/entra_id/callback'
    end

    assert_equal :invalid_credentials, request.env['omniauth.error.type']
    assert_not session.key? 'warden.user.user.key'
    assert_redirected_to new_user_session_path
  end
end

class OmniauthCallbacksSamlTest < OmniauthIntegrationTestCase
  test 'get first user or create' do
    valid_saml_login_setup
    assert_difference 'User.count' do
      get '/users/auth/saml/callback'
    end

    assert session.key? 'warden.user.user.key'
    assert_equal session['warden.user.user.key'][0][0], User.last.id
    assert_redirected_to root_path
  end

  test 'invalid get first user or create' do
    invalid_saml_login_setup
    assert_no_changes 'User.count' do
      get '/users/auth/saml/callback'
    end

    assert_equal :invalid_credentials, request.env['omniauth.error.type']
    assert_not session.key? 'warden.user.user.key'
    assert_redirected_to new_user_session_path
  end
end
