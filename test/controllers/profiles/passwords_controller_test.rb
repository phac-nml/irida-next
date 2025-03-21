# frozen_string_literal: true

require 'test_helper'

module Profiles
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get edit' do
      sign_in users(:john_doe)

      get edit_profile_password_url
      assert_response :success

      w3c_validate 'User Profile Password Edit Page'
    end

    test 'should update user password' do
      sign_in users(:john_doe)

      patch profile_password_path,
            params: { user: { password: 'password', password_confirmation: 'password', current_password: 'password1' } }
      assert_response :redirect
    end

    test 'should not update user password with empty password' do
      sign_in users(:john_doe)

      patch profile_password_path,
            params: { user: { password: '', password_confirmation: '', current_password: 'password1' } }
      assert_response :unprocessable_entity
    end

    test 'omniauth user should not update password' do
      sign_in users(:jeff_doe)

      patch profile_password_path,
            params: { user: { password: 'password', password_confirmation: 'password', current_password: 'password1' } }
      assert_response :unauthorized
    end
  end
end
