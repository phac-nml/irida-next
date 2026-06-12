# frozen_string_literal: true

require 'test_helper'

module Profiles
  class ExperimentalFeaturesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:john_doe)
    end

    test 'should get show' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config) do
        get profile_experimental_features_url
      end

      assert_response :success
      w3c_validate 'User Profile Experimental Features Page'
    end

    test 'show renders empty state when no features are eligible' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config(allowlist: [users(:jane_doe).email])) do
        get profile_experimental_features_path
      end

      assert_response :success
      assert_includes response.body, I18n.t('profiles.experimental_features.show.empty_state.title')
    end

    test 'show renders eligible feature name and switch control' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config) do
        get profile_experimental_features_path
      end

      assert_response :success
      assert_includes response.body, 'Data Grid Samples Table'
      assert_select 'fieldset input[type="checkbox"][role="switch"]'
      assert_select '#experimental-feature-data_grid_samples_table-status[role="status"]', false
      assert_select '#experimental-feature-data_grid_samples_table-status[aria-live]', false
      assert_select '#experimental-feature-data_grid_samples_table-status.break-words'
      assert_select '#experimental-feature-data_grid_samples_table-status.whitespace-nowrap', false
    end

    test 'turbo_stream update enables actor gate for eligible feature' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config) do
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id

        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '1' } }

        assert_response :ok
        assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        assert_includes response.body, 'turbo-stream action="replace"'
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'turbo_stream update disables actor gate for eligible feature' do
      sign_in @user
      Flipper.enable_actor(:data_grid_samples_table, @user)

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '0' } }

        assert_response :ok
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        assert_includes response.body, 'turbo-stream action="replace"'
      end
    end

    test 'turbo_stream update rejects non-allowlisted feature requests' do
      sign_in @user
      Flipper.expects(:enable_actor).never

      with_user_opt_in_features(user_opt_in_feature_config(allowlist: [users(:jane_doe).email])) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '1' } }
      end

      assert_response :unprocessable_content
      assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      assert_includes response.body, 'turbo-stream action="replace"'
      assert_includes response.body, I18n.t('profiles.experimental_features.update.not_eligible')
    end

    test 'turbo_stream update returns validation error for invalid enabled value' do
      sign_in @user
      Flipper.expects(:enable_actor).never

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: 'yes' } }
      end

      assert_response :unprocessable_content
      assert_includes response.body, 'turbo-stream action="replace"'
      assert_includes response.body, I18n.t('profiles.experimental_features.update.validation_error')
    end

    test 'turbo_stream update returns empty response for unknown feature key' do
      sign_in @user
      Flipper.expects(:enable_actor).never

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'unknown_feature', enabled: '1' } }
      end

      assert_response :unprocessable_content
      assert_not_includes response.body, 'turbo-stream'
    end

    test 'turbo_stream update returns validation error when params are incomplete' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table' } }
      end

      assert_response :unprocessable_content
      assert_includes response.body, 'turbo-stream action="replace"'
      assert_includes response.body, I18n.t('profiles.experimental_features.update.validation_error')
    end

    test 'turbo_stream update returns flipper error message when toggle fails' do
      sign_in @user
      Flipper.expects(:enable_actor).raises(Flipper::Error, 'adapter failed')
      Rails.logger.expects(:error).with(regexp_matches(/adapter failed/))

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '1' } }
      end

      assert_response :unprocessable_content
      assert_includes response.body, 'turbo-stream action="replace"'
      assert_includes response.body, I18n.t('profiles.experimental_features.update.error')
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'turbo_stream update includes success message when enabled' do
      sign_in @user

      with_user_opt_in_features(user_opt_in_feature_config) do
        patch profile_experimental_features_path(format: :turbo_stream),
              params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '1' } }

        assert_includes response.body, I18n.t('profiles.experimental_features.update.success')
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'should redirect unauthenticated users on update' do
      patch profile_experimental_features_path(format: :turbo_stream),
            params: { opt_in_form: { feature_key: 'data_grid_samples_table', enabled: '1' } }

      assert_response :redirect
    end
  end
end
