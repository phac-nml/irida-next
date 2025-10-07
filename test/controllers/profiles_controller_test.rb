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

    assert_equal('john.doe@localhost', u.email)
    assert_equal('John', u.first_name)
    assert_equal('Doe', u.last_name)

    patch profile_url, params: { user:
    {
      email: 'johnny.deer@localhost',
      first_name: 'johnny',
      last_name: 'deer'
    } }

    assert_response :redirect
    assert_equal('johnny.deer@localhost', u.email)
    assert_equal('johnny', u.first_name)
    assert_equal('deer', u.last_name)
  end

  test 'should not update a users email with a blank email' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { email: '' } }
    assert_response :unprocessable_content
  end

  test 'should not update a users first_name with a blank first_name' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { first_name: '' } }
    assert_response :unprocessable_content
  end

  test 'should not update a users last_name with a blank last_name' do
    sign_in users(:john_doe)

    patch profile_url, params: { user: { last_name: '' } }
    assert_response :unprocessable_content
  end
end
