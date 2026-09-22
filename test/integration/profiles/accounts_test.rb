# frozen_string_literal: true

require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get account show' do
    get profile_account_url

    assert_response :success
  end

  test 'should redirect unauthenticated users from account show' do
    sign_out @user

    get profile_account_url

    assert_redirected_to new_user_session_url
  end

  test 'can delete profile' do
    assert_difference('User.count', -1) do
      delete profile_account_path
    end

    assert_redirected_to new_user_session_url
    assert_not User.exists?(@user.id)
  end

  test 'should not delete profile for unauthenticated users' do
    sign_out @user

    assert_no_difference('User.count') do
      delete profile_account_path
    end

    assert_redirected_to new_user_session_url
  end
end
