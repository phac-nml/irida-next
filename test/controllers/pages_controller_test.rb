# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get accessibility' do
    sign_in users(:john_doe)

    get accessibility_path
    assert_response :success
  end
end
