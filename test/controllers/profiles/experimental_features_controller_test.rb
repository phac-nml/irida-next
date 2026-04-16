# frozen_string_literal: true

require 'test_helper'

module Profiles
  class ExperimentalFeaturesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:john_doe)
      @other_user = users(:jane_doe)
      Flipper.add(:data_grid_samples_table) unless Flipper.exist?(:data_grid_samples_table)
      Flipper.disable(:data_grid_samples_table)
    end

    def teardown
      Flipper.disable_actor(:data_grid_samples_table, @user) if Flipper.exist?(:data_grid_samples_table)
      Flipper.disable_actor(:data_grid_samples_table, @other_user) if Flipper.exist?(:data_grid_samples_table)
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

    test 'should render eligible feature when user email is allowlisted' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_email_allowlist = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => [@user.email.upcase],
            'name' => { 'en' => 'Data Grid Samples Table' },
            'description' => { 'en' => 'Enable the new data grid for the samples table.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_email_allowlist) }

      get profile_experimental_features_url

      assert_response :success
      assert_select "div[id='experimental-feature-data_grid_samples_table']", count: 1
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should render empty state when user email is not allowlisted' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_email_allowlist = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => [@other_user.email],
            'name' => { 'en' => 'Data Grid Samples Table' },
            'description' => { 'en' => 'Enable the new data grid for the samples table.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_email_allowlist) }

      get profile_experimental_features_url

      assert_response :success
      assert_select 'p', text: I18n.t('profiles.experimental_features.show.empty_state.title')
      assert_select "div[id='experimental-feature-data_grid_samples_table']", count: 0
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should enable actor for allowlisted email feature via turbo_stream' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_email_allowlist = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => [@user.email.upcase],
            'name' => { 'en' => 'Data Grid Samples Table' },
            'description' => { 'en' => 'Enable the new data grid for the samples table.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_email_allowlist) }

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }

      assert_response :ok
      assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should reject update when user email is not allowlisted' do
      sign_in @other_user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_email_allowlist = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => [@user.email],
            'name' => { 'en' => 'Data Grid Samples Table' },
            'description' => { 'en' => 'Enable the new data grid for the samples table.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_email_allowlist) }

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }

      assert_response :forbidden
      assert_match I18n.t('profiles.experimental_features.update.not_eligible'), response.body
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@other_user.flipper_id)
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should reject non-allowlisted feature key' do
      sign_in @user
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'not_a_real_feature', enabled: '1' }
      assert_response :forbidden
      assert_match I18n.t('profiles.experimental_features.update.not_eligible'), response.body
      assert_match 'target="flashes"', response.body
      # Flipper must not have been modified for the invalid key
      assert_not Flipper.exist?(:not_a_real_feature)
    end

    test 'should reject missing feature key' do
      sign_in @user
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { enabled: '1' }

      assert_response :unprocessable_content
      assert_match I18n.t('profiles.experimental_features.update.error'), response.body
      assert_match 'target="flashes"', response.body
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    end

    test 'should reject invalid enabled value' do
      sign_in @user
      Flipper.enable_actor(:data_grid_samples_table, @user)

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: 'banana' }

      assert_response :unprocessable_content
      assert_match I18n.t('profiles.experimental_features.update.error'), response.body
      assert_match 'target="flashes"', response.body
      assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
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

    test 'should render feature name from config' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_custom_name = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => 'all',
            'name' => { 'en' => 'Custom Config Feature Name' },
            'description' => { 'en' => 'Custom config description.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_custom_name) }
      get profile_experimental_features_url
      assert_response :success
      assert_match 'Custom Config Feature Name', response.body
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should render French feature name from config when locale is fr' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_with_fr = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => 'all',
            'name' => { 'en' => 'Data Grid Samples Table', 'fr' => 'Grille de données config' },
            'description' => { 'en' => 'Enable the new data grid.', 'fr' => 'Activer la grille config.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_with_fr) }
      get profile_experimental_features_url, params: { locale: 'fr' }
      assert_response :success
      assert_match 'Grille de données config', response.body
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end

    test 'should fall back to English name when current locale missing from config' do
      sign_in @user
      original_config = USER_OPT_IN_FEATURE_CONFIG.dup
      config_en_only = {
        'user_opt_in_features' => {
          'data_grid_samples_table' => {
            'allowlist' => 'all',
            'name' => { 'en' => 'English Only Feature Name' },
            'description' => { 'en' => 'English only description.' }
          }
        }
      }
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, config_en_only) }
      get profile_experimental_features_url, params: { locale: 'fr' }
      assert_response :success
      assert_match 'English Only Feature Name', response.body
    ensure
      silence_warnings { Object.const_set(:USER_OPT_IN_FEATURE_CONFIG, original_config) }
    end
  end
end
