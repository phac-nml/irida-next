# frozen_string_literal: true

require 'application_system_test_case'

class PasswordsTest < ApplicationSystemTestCase
  setup do
    @settings = Irida::CurrentSettings.current_application_settings
    @original_password_authentication_enabled = @settings.password_authentication_enabled

    @settings.update(password_authentication_enabled: true)
  end

  teardown do
    @settings.update(password_authentication_enabled: @original_password_authentication_enabled)
  end

  test 'invalid password reset request focuses the summary and linked control' do
    required_error = I18n.t('devise.passwords.new.email.required_error')

    visit new_user_password_path

    click_button I18n.t(:'devise.passwords.new.submit_button')

    assert_selector '[data-controller="form-error-summary"]', focused: true
    assert_selector '#user_email_error', text: required_error

    within '[data-controller="form-error-summary"]' do
      click_link required_error
    end

    assert_selector '#user_email', focused: true
    assert_accessible
  end
end
