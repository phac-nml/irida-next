require "test_helper"

class Profiles::AccountControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get profiles_account_show_url
    assert_response :success
  end

  test "should get update" do
    get profiles_account_update_url
    assert_response :success
  end
end
