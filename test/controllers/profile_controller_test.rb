require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get profile_show_url
    assert_response :success
  end

  test "should get update" do
    get profile_update_url
    assert_response :success
  end
end
