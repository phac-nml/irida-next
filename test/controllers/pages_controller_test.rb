# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get accessibility' do
    Flipper.enable(:accessibility_statement)
    sign_in users(:john_doe)

    get accessibility_path
    assert_response :success
  end

  test 'should return not found when accessibility statement feature is disabled' do
    Flipper.disable(:accessibility_statement)
    sign_in users(:john_doe)

    get accessibility_path
    assert_response :not_found
  end
end
