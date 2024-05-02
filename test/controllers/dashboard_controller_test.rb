# frozen_string_literal: true

require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'authenticated users can see dashboard' do
    sign_in users(:john_doe)

    get root_url
    assert_response :redirect
    assert_redirected_to dashboard_projects_path
  end
end
