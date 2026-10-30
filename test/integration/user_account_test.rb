# frozen_string_literal: true

require 'test_helper'

class UserAccountTest < ActionDispatch::IntegrationTest
  setup do
    @settings = Irida::CurrentSettings.current_application_settings
    @original_signup_enabled = @settings.signup_enabled
    @original_password_authentication_enabled = @settings.password_authentication_enabled

    @settings.update(signup_enabled: true, password_authentication_enabled: true)
  end

  teardown do
    @settings.update(
      signup_enabled: @original_signup_enabled,
      password_authentication_enabled: @original_password_authentication_enabled
    )
  end

  test 'invalid password reset request focuses the summary and linked control' do
    required_error = I18n.t('devise.passwords.new.email.required_error')

    get new_user_password_path

    assert_response :success
    assert_select 'div[data-controller="form-error-summary"][tabindex="-1"]'
    assert_select '#user_email_error'
    assert_select '[data-controller="form-error-summary"] a[href="#user_email"]', text: required_error
    assert_select '#user_email[data-email-input-target="emailField"]'
  end

  test 'invalid sign up focuses the summary and linked control' do
    post user_registration_path, params: { user: {} }

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"][tabindex="-1"]'
    assert_select '#user_email_error', text: "Email can't be blank"
    assert_select '[data-controller="form-error-summary"] a[href="#user_email"]', text: "Email can't be blank"
    assert_select '#user_email[aria-describedby="user_email_error"][aria-invalid="true"]'
  end

  test 'invalid account update focuses the summary and linked control' do
    user = users(:john_doe)
    sign_in user

    put user_registration_path, params: {
      user: {
        email: user.email,
        password: '',
        password_confirmation: '',
        current_password: ''
      }
    }

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"][tabindex="-1"]'
    assert_select '#user_current_password_error', text: "Current password can't be blank"
    assert_select '[data-controller="form-error-summary"] a[href="#user_current_password"]',
                  text: "Current password can't be blank"
    assert_select '#user_current_password[aria-describedby="user_current_password_error"][aria-invalid="true"]'
  end

  test 'should show the user' do
    user = users(:john_doe)
    sign_in user

    get user_path(user.namespace.path)

    assert_response :success
    w3c_validate 'User Profile Page'
  end

  test 'should not show the user' do
    sign_in users(:john_doe)

    get user_path(users(:james_doe).namespace.path)

    assert_response :unauthorized
  end

  test 'authenticated users can see dashboard' do
    sign_in users(:john_doe)

    get root_url

    assert_response :redirect
    assert_redirected_to dashboard_projects_path
  end
end
