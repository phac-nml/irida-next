# frozen_string_literal: true

require 'test_helper'

module Dashboard
  class ProjectsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get index' do
      sign_in users(:john_doe)

      get dashboard_projects_path
      assert_response :success

      w3c_validate 'Projects Dashboard'
    end
  end
end
