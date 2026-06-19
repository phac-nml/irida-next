# frozen_string_literal: true

require 'test_helper'

# Tests for the ActivitiesController
class ActiveAdminRoutesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should redirect to login page if not authenticated' do
    get admin_root_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'non system users should not have access to active admin' do
    sign_in users(:john_doe)

    get admin_root_path
    assert_response :not_found
  end

  test 'system users should have access to active admin' do
    sign_in users(:system_user)

    get admin_root_path
    assert_response :success
  end
end
