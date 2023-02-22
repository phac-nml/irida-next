# frozen_string_literal: true

require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get show' do
    sign_in users(:john_doe)

    get profile_url
    assert_response :success
  end

  test 'should update a users email' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { email: 'your.email+fakedata57424@gmail.com' } }
    assert_response :success
  end

  test 'should not update a users email with a blank email' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { email: '' } }
    assert_response :unprocessable_entity
  end
end
