# frozen_string_literal: true

require 'application_system_test_case'

class RegistrationsTest < ApplicationSystemTestCase
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

  test 'invalid sign up focuses the summary and linked control' do
    visit new_user_registration_path

    click_button I18n.t(:'devise.registrations.new.submit_button')

    assert_selector '[data-controller="form-error-summary"]', focused: true
    assert_selector '#user_email_error', text: "Email can't be blank"

    within '[data-controller="form-error-summary"]' do
      click_link "Email can't be blank"
    end

    assert_selector '#user_email', focused: true
    assert_accessible
  end

  test 'invalid account update focuses the summary and linked control' do
    login_as users(:john_doe)

    visit edit_user_registration_path

    click_button I18n.t('common.actions.update')

    assert_selector '[data-controller="form-error-summary"]', focused: true
    assert_selector '#user_current_password_error', text: "Current password can't be blank"

    within '[data-controller="form-error-summary"]' do
      click_link "Current password can't be blank"
    end

    assert_selector '#user_current_password', focused: true
    assert_accessible
  end
end
