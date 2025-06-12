# frozen_string_literal: true

require 'test_helper'

module Profiles
  class PreferencesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get show' do
      sign_in users(:john_doe)

      get profile_preferences_url
      assert_response :success

      w3c_validate 'User Profile Preferences Page'
    end

    test 'should update the users locale with a valid locale' do
      sign_in users(:john_doe)

      patch profile_preferences_path,
            params: { user: { locale: 'fr' } }
      assert_response :redirect
      assert_redirected_to profile_preferences_path
    end

    test 'should update the users locale with a valid locale via turbo_stream' do
      sign_in users(:john_doe)

      patch profile_preferences_path(format: :turbo_stream),
            params: { user: { locale: 'fr' } }
      assert_response :ok
    end

    test 'shouldn\'t update the users locale with an invalid locale' do
      sign_in users(:john_doe)

      patch profile_preferences_path,
            params: { user: { locale: 'not_a_locale' } }
      assert_response :unprocessable_entity
    end

    test 'shouldn\'t update the users locale with an invalid locale via turbo_stream' do
      sign_in users(:john_doe)

      patch profile_preferences_path(format: :turbo_stream),
            params: { user: { locale: 'not_a_locale' } }
      assert_response :unprocessable_entity
    end
  end
end
