# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should show the user' do
    sign_in users(:john_doe)

    get user_path(users(:john_doe).namespace.full_path)
    assert_response :success
  end
end
