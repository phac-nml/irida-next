# frozen_string_literal: true

require 'test_helper'

module Profiles
  class ExperimentalFeaturesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:john_doe)
      Flipper.add(:data_grid_samples_table) unless Flipper.exist?(:data_grid_samples_table)
      Flipper.disable(:data_grid_samples_table)
    end

    def teardown
      Flipper.disable_actor(:data_grid_samples_table, @user) if Flipper.exist?(:data_grid_samples_table)
    end

    test 'should get show' do
      sign_in @user
      get profile_experimental_features_url
      assert_response :success
      w3c_validate 'User Profile Experimental Features Page'
    end

    test 'should render empty state when no features eligible' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, { 'user_opt_in_features' => {} }) }
      get profile_experimental_features_url
      assert_response :success
      assert_select 'p', text: I18n.t('profiles.experimental_features.show.empty_state.title')
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should render eligible feature with toggle' do
      sign_in @user
      get profile_experimental_features_url
      assert_response :success
      assert_select "div[id^='experimental-feature-']"
      assert_select 'form[method=post]' do
        assert_select 'input[name="_method"][value=patch]'
      end
    end

    test 'should enable actor for allowlisted feature via turbo_stream' do
      sign_in @user
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }
      assert_response :ok
      assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    end

    test 'should disable actor for allowlisted feature via turbo_stream' do
      sign_in @user
      Flipper.enable_actor(:data_grid_samples_table, @user)
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '0' }
      assert_response :ok
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    end

    test 'should reject non-allowlisted feature key' do
      sign_in @user
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'not_a_real_feature', enabled: '1' }
      assert_response :ok
      # Response contains inline error text (turbo stream renders error message)
      assert_match I18n.t('profiles.experimental_features.update.error'), response.body
      # Flipper must not have been modified for the invalid key
      assert_not Flipper.exist?(:not_a_real_feature)
    end

    test 'should redirect unauthenticated user to sign in' do
      get profile_experimental_features_url
      assert_response :redirect
    end

    test 'should update via HTML format redirect back' do
      sign_in @user
      patch profile_experimental_features_path,
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }
      assert_response :redirect
      assert_redirected_to profile_experimental_features_path
    end
  end
end
