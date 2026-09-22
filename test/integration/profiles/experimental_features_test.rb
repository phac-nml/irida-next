# frozen_string_literal: true

require 'test_helper'

module Profiles
  class ExperimentalFeaturesTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      sign_in @user
      @feature_name = :data_grid_samples_table
    end

    test 'should get show' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        get profile_experimental_features_path
      end

      assert_response :success
      assert_includes response.body, Irida::ExperimentalFeatureCatalog.fetch(@feature_name)[:name]
    end

    test 'show renders empty state when no features are eligible' do
      with_user_opt_in_features(user_opt_in_feature_config(allowlist: [users(:jane_doe).email])) do
        get profile_experimental_features_path
      end

      assert_response :success
      assert_includes response.body, I18n.t('profiles.experimental_features.show.empty_state.title')
    end

    test 'should enable an eligible feature via turbo stream' do
      assert_changes -> { Flipper[@feature_name].enabled?(@user) }, from: false, to: true do
        with_user_opt_in_features(user_opt_in_feature_config) do
          patch profile_experimental_features_path(format: :turbo_stream),
                params: { opt_in_form: { feature_key: @feature_name, enabled: '1' } }
        end
      end

      assert_response :ok
      assert_includes response.body, I18n.t('profiles.experimental_features.update.success')
    ensure
      Flipper.disable_actor(@feature_name, @user)
    end

    test 'should set a success flash when enabling an eligible feature via HTML' do
      assert_changes -> { Flipper[@feature_name].enabled?(@user) }, from: false, to: true do
        with_user_opt_in_features(user_opt_in_feature_config) do
          patch profile_experimental_features_path,
                params: { opt_in_form: { feature_key: @feature_name, enabled: '1' } }
        end
      end

      assert_redirected_to profile_experimental_features_path
      assert_equal I18n.t(:'profiles.experimental_features.update.success'), flash[:success]
    ensure
      Flipper.disable_actor(@feature_name, @user)
    end

    test 'should set an error flash when enabling an ineligible feature via HTML' do
      assert_no_changes -> { Flipper[@feature_name].enabled?(@user) } do
        with_user_opt_in_features(user_opt_in_feature_config(allowlist: [users(:jane_doe).email])) do
          patch profile_experimental_features_path,
                params: { opt_in_form: { feature_key: @feature_name, enabled: '1' } }
        end
      end

      assert_redirected_to profile_experimental_features_path
      assert_equal I18n.t(:'profiles.experimental_features.update.not_eligible'), flash[:error]
    end

    test 'should disable an enabled feature via turbo stream' do
      Flipper.enable_actor(@feature_name, @user)

      assert_changes -> { Flipper[@feature_name].enabled?(@user) }, from: true, to: false do
        with_user_opt_in_features(user_opt_in_feature_config) do
          patch profile_experimental_features_path(format: :turbo_stream),
                params: { opt_in_form: { feature_key: @feature_name, enabled: '0' } }
        end
      end

      assert_response :ok
      assert_not Flipper[@feature_name].enabled?(@user)
    end

    test 'should return validation error for invalid enabled value' do
      Flipper.expects(:enable_actor).never

      assert_no_changes -> { Flipper[@feature_name].enabled?(@user) } do
        with_user_opt_in_features(user_opt_in_feature_config) do
          patch profile_experimental_features_path(format: :turbo_stream),
                params: { opt_in_form: { feature_key: @feature_name, enabled: 'yes' } }
        end
      end

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('profiles.experimental_features.update.validation_error')
    end

    test 'should return an error when the feature toggle fails' do
      Flipper.expects(:enable_actor).with(@feature_name, @user).raises(Flipper::Error, 'adapter failed')
      Rails.logger.expects(:error).with(regexp_matches(/adapter failed/))

      assert_no_changes -> { Flipper[@feature_name].enabled?(@user) } do
        with_user_opt_in_features(user_opt_in_feature_config) do
          patch profile_experimental_features_path(format: :turbo_stream),
                params: { opt_in_form: { feature_key: @feature_name, enabled: '1' } }
        end
      end

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('profiles.experimental_features.update.error')
    ensure
      Flipper.disable_actor(@feature_name, @user)
    end

    test 'should redirect HTML submissions without an opt-in form' do
      patch profile_experimental_features_path

      assert_redirected_to profile_experimental_features_path
      assert_equal I18n.t(:'profiles.experimental_features.update.validation_error'), flash[:error]
    end

    test 'should reject turbo stream submissions without an opt-in form' do
      patch profile_experimental_features_path(format: :turbo_stream)

      assert_response :unprocessable_content
      assert_empty response.body
    end
  end
end
