# frozen_string_literal: true

require 'test_helper'
require 'application_system_test_case'
require 'test_helpers/w3c_validation_helpers'

module Accessibility
  include W3cValidationHelpers

  class UserTest < ApplicationSystemTestCase
    test 'user page is accessible' do
      sign_in users(:john_doe)

      visit user_path(users(:john_doe).namespace.path)
      assert_equal 200, page.status_code

      assert_accessible
      w3c_validate 'User Profile Page', content: page.body
    end
  end
end
