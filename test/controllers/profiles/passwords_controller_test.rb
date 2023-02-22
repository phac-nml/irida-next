# frozen_string_literal: true

require 'test_helper'

module Profiles
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get edit' do
      sign_in users(:john_doe)

      get edit_profile_password_url
      assert_response :success
    end

    test 'should update user password' do
      sign_in users(:john_doe)

      patch profile_password_url,
            params: { user: { password: 'password', password_confirmation: 'password', current_password: 'password1' } }
      assert_response :success
    end
  end
end
