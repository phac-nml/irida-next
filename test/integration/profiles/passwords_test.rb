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
    w3c_validate 'User Profile Password Edit Page'
  end

  test 'should update user password' do
    assert_changes -> { @user.reload.valid_password?('new_password') } do
      patch profile_password_path,
            params: { user: { password: 'new_password', password_confirmation: 'new_password',
                              current_password: 'password1' } }
    end

    assert_redirected_to edit_profile_password_path
    assert_equal I18n.t(:'profiles.passwords.update.success'), flash[:success]
  end

  test 'should not update user password with empty password' do
    assert_no_changes -> { @user.reload.valid_password?('password1') } do
      patch profile_password_path,
            params: { user: { password: '', password_confirmation: '', current_password: 'password1' } }
    end

    assert_response :unprocessable_content
  end

  test 'omniauth user should not update password' do
    sign_in users(:jeff_doe)

    patch profile_password_path,
          params: { user: { password: 'password', password_confirmation: 'password', current_password: 'password1' } }

    assert_response :unauthorized
  end
end
