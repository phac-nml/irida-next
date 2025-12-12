# frozen_string_literal: true

require 'test_helper'

module Dashboard
  class GroupsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get index' do
      sign_in users(:john_doe)

      get dashboard_groups_path
      assert_response :success

      w3c_validate 'Groups Dashboard'
    end

    test 'accessing groups index on invalid page causes pagy overflow redirect' do
      sign_in users(:john_doe)

      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::OverflowError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get dashboard_groups_path(page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
