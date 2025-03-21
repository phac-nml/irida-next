# frozen_string_literal: true

require 'test_helper'

module Profiles
  class AccountsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get show' do
      sign_in users(:john_doe)

      get profile_account_url
      assert_response :success

      w3c_validate 'User Profile Account Page'
    end

    test 'should delete users account' do
      sign_in users(:john_doe)

      delete profile_account_url
      assert_response :redirect
    end
  end
end
