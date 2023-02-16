require "test_helper"

class Profiles::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get profiles_passwords_edit_url
    assert_response :success
  end

  test "should get update" do
    get profiles_passwords_update_url
    assert_response :success
  end
end
