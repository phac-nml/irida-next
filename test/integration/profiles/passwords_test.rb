# frozen_string_literal: true

require 'test_helper'

class PasswordsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get edit' do
    get edit_profile_password_url

    assert_response :success
    assert_password_form
  end

  test 'omniauth user should not see the password form' do
    sign_in users(:jeff_doe)

    get edit_profile_password_url

    assert_response :success
    assert_select "form[action='#{profile_password_path}']", count: 0
  end

  test 'should update user password' do
    assert_changes -> { @user.reload.valid_password?('new_password') } do
      patch profile_password_path,
            params: { user: { password: 'new_password', password_confirmation: 'new_password',
                              current_password: 'password1' } }
    end

    assert_redirected_to edit_profile_password_path
    follow_redirect!
    assert_response :success
    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div', "#{I18n.t('common.statuses.success')}: #{I18n.t(:'profiles.passwords.update.success')}"
    end
    assert_password_form
  end

  test 'should not update user password with empty password' do
    assert_no_changes -> { @user.reload.valid_password?('password1') } do
      patch profile_password_path,
            params: { user: { password: '', password_confirmation: '', current_password: 'password1' } }
    end

    assert_response :unprocessable_content
    assert_password_form
    assert_select '#user_password_error li', minimum: 1
  end

  test 'should show current password and confirmation errors' do
    patch profile_password_path,
          params: { user: { password: 'new_password', password_confirmation: 'different_password',
                            current_password: '' } }

    assert_response :unprocessable_content
    assert_password_form
    assert_select '#user_current_password_error li', minimum: 1
    assert_select '#user_password_confirmation_error li', minimum: 1
  end

  test 'omniauth user should not update password' do
    sign_in users(:jeff_doe)

    patch profile_password_path,
          params: { user: { password: 'password', password_confirmation: 'password', current_password: 'password1' } }

    assert_response :unauthorized
    assert_select "form[action='#{profile_password_path}']", count: 0
  end

  private

  def assert_password_form
    assert_select 'h1', text: I18n.t(:'profiles.passwords.update.title'), count: 1
    assert_select "form[action='#{profile_password_path}'][method='post']" do
      assert_select "input[name='_method'][value='patch']", count: 1
      assert_select 'input#user_current_password[type="password"]', count: 1
      assert_select 'input#user_password[type="password"]', count: 1
      assert_select 'input#user_password_confirmation[type="password"]', count: 1
    end
  end
end
