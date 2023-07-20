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

    patch profile_url, params: { user: { email: 'your.email@gmail.com' } }
    assert_response :redirect
  end

  test 'should update user fields' do
    u = users(:john_doe)
    sign_in u

    assert_equal("john.doe@localhost", u.email)
    assert_nil(u.first_name)
    assert_nil(u.last_name)
    assert_nil(u.phone_number)

    patch profile_url, params: { user: {
      email: 'john.doe@gmail.com',
      first_name: 'john',
      last_name: 'doe',
      phone_number: '1234'
      } }

    assert_response :redirect
    assert_equal("john.doe@gmail.com", u.email)
    assert_equal("john", u.first_name)
    assert_equal("doe", u.last_name)
    assert_equal("1234", u.phone_number)
  end

  test 'should not update a users email with a blank email' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { email: '' } }
    assert_response :unprocessable_entity
  end
end
