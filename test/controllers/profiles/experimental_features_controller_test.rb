# frozen_string_literal: true

require 'test_helper'

module Profiles
  class ExperimentalFeaturesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:john_doe)
      @other_user = users(:jane_doe)
      @original_user_opt_in_features = current_application_settings.user_opt_in_features.deep_dup
      update_user_opt_in_features(default_user_opt_in_features)
      Flipper.add(:data_grid_samples_table) unless Flipper.exist?(:data_grid_samples_table)
      Flipper.disable(:data_grid_samples_table)
    end

    def teardown
      current_application_settings.update!(user_opt_in_features: @original_user_opt_in_features || {})
      return unless Flipper.exist?(:data_grid_samples_table)

      Flipper.disable_actor(:data_grid_samples_table, @user)
      Flipper.disable_actor(:data_grid_samples_table, @other_user)
      Flipper.disable(:data_grid_samples_table)
    end

    test 'should get show' do
      sign_in @user
      get profile_experimental_features_url
      assert_response :success
      w3c_validate 'User Profile Experimental Features Page'
    end

    test 'should render empty state when no features eligible' do
      sign_in @user
      update_user_opt_in_features({})
      get profile_experimental_features_url
      assert_response :success
      assert_select 'p', text: I18n.t('profiles.experimental_features.show.empty_state.title')
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

    test 'should render toggle unchecked when feature is globally enabled but actor is not opted in' do
      sign_in @user
      Flipper.enable(:data_grid_samples_table)

      get profile_experimental_features_url

      assert_response :success
      assert_select '#experimental-feature-data_grid_samples_table-toggle[checked]', count: 0
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    ensure
      Flipper.disable(:data_grid_samples_table)
    end

    test 'should render toggle with switch semantics and status association' do
      sign_in @user
      update_user_opt_in_features(default_user_opt_in_features(allowlist: [@user.email]))

      get profile_experimental_features_url

      assert_response :success
      assert_select "input[type='checkbox'][id$='-toggle'][role='switch'][aria-describedby$='-status']"
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
      update_user_opt_in_features(default_user_opt_in_features(allowlist: [@user.email.upcase]))

      get profile_experimental_features_url

      assert_response :success
      assert_select "div[id='experimental-feature-data_grid_samples_table']", count: 1
    end

    test 'should render empty state when user email is not allowlisted' do
      sign_in @user
      update_user_opt_in_features(default_user_opt_in_features(allowlist: [@other_user.email]))

      get profile_experimental_features_url

      assert_response :success
      assert_select 'p', text: I18n.t('profiles.experimental_features.show.empty_state.title')
      assert_select "div[id='experimental-feature-data_grid_samples_table']", count: 0
    end

    test 'should enable actor for allowlisted email feature via turbo_stream' do
      sign_in @user
      update_user_opt_in_features(default_user_opt_in_features(allowlist: [@user.email.upcase]))

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }

      assert_response :ok
      assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    end

    test 'should reject update when user email is not allowlisted' do
      sign_in @other_user
      update_user_opt_in_features(default_user_opt_in_features(allowlist: [@user.email]))

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table', enabled: '1' }

      assert_response :forbidden
      assert_match I18n.t('profiles.experimental_features.update.not_eligible'), response.body
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@other_user.flipper_id)
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

    test 'should reject malformed feature key params' do
      sign_in @user

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data-grid-samples-table', enabled: '1' }

      assert_response :unprocessable_content
      assert_match I18n.t('profiles.experimental_features.update.error'), response.body
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
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

    test 'should reject missing enabled param' do
      sign_in @user

      patch profile_experimental_features_path(format: :turbo_stream),
            params: { feature_key: 'data_grid_samples_table' }

      assert_response :unprocessable_content
      assert_match I18n.t('profiles.experimental_features.update.error'), response.body
      assert_match 'target="flashes"', response.body
      assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
    end

    test 'should handle flipper failure gracefully when enabling actor' do
      sign_in @user

      Flipper.stubs(:enable_actor).raises(Flipper::Error, 'simulated flipper failure')

      begin
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { feature_key: 'data_grid_samples_table', enabled: '1' }

        assert_response :unprocessable_content
        assert_match I18n.t('profiles.experimental_features.update.error'), response.body
        assert_match 'target="flashes"', response.body
        assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
      ensure
        Flipper.unstub(:enable_actor)
      end
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
      update_user_opt_in_features(
        default_user_opt_in_features(
          name_en: 'Custom Config Feature Name',
          description_en: 'Custom config description.'
        )
      )
      get profile_experimental_features_url
      assert_response :success
      assert_match 'Custom Config Feature Name', response.body
    end

    test 'should render French feature name from config when locale is fr' do
      sign_in @user
      update_user_opt_in_features(
        default_user_opt_in_features(
          name_fr: 'Grille de données config',
          description_en: 'Enable the new data grid.',
          description_fr: 'Activer la grille config.'
        )
      )
      get profile_experimental_features_url, params: { locale: 'fr' }
      assert_response :success
      assert_match 'Grille de données config', response.body
    end

    test 'should fall back to English name when current locale missing from config' do
      sign_in @user
      update_user_opt_in_features(
        default_user_opt_in_features(
          name_en: 'English Only Feature Name',
          description_en: 'English only description.'
        )
      )
      get profile_experimental_features_url, params: { locale: 'fr' }
      assert_response :success
      assert_match 'English Only Feature Name', response.body
    end
  end
end
