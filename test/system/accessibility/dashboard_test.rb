# frozen_string_literal: true

require 'test_helper'
require 'application_system_test_case'
require 'test_helpers/w3c_validation_helpers'

module Accessibility
  include W3cValidationHelpers

  class DashboardTest < ApplicationSystemTestCase
    test 'dashboard is accessible' do
      sign_in users(:john_doe)

      visit dashboard_projects_path
      assert_equal 200, page.status_code

      assert_accessible
      w3c_validate 'Projects Dashboard', content: page.body
    end
  end
end
