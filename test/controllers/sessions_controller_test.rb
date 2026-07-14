# frozen_string_literal: true

require 'test_helper'

class SessionControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should set Clear-Site-Data header on sign_out' do
    sign_in users(:john_doe)

    delete destroy_user_session_path

    assert_equal '"cookies", "storage", "cache"', response.headers['Clear-Site-Data']
  end

  test 'should update the user locale when locale param is present on sign in' do
    assert_changes -> { users(:john_doe).reload.locale }, from: 'en', to: 'fr' do
      post user_session_path, params: {
        user: {
          email: users(:john_doe).email,
          password: 'password1'
        },
        locale: 'fr'
      }
    end
  end
end
