# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should show the user' do
    sign_in users(:john_doe)

    get user_path(users(:john_doe))
    assert_response :success

    w3c_validate 'User Profile Page'
  end

  test 'should not show the user' do
    sign_in users(:john_doe)

    get user_path(users(:james_doe))
    assert_response :unauthorized
  end
end
