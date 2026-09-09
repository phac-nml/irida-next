# frozen_string_literal: true

require 'test_helper'

module Admin
  class FeatureFlagsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:system_user)
      @feature_key = 'data_grid_samples_table'
      @feature_name = Irida::ExperimentalFeatureCatalog.fetch(@feature_key)[:name]
    end

    test 'system user can view feature flags index' do
      Flipper.disable(@feature_key)

      get admin_feature_flags_path

      assert_response :success
      assert_includes response.body, I18n.t('active_admin.feature_flags.title')
      assert_includes response.body, @feature_name
      assert_includes response.body, I18n.t('active_admin.feature_flags.state.disabled')
      assert_includes response.body, I18n.t('active_admin.feature_flags.opt_in.off')
      # Guard against missing i18n keys rendering on the page.
      assert_no_match(/translation missing/i, response.body)
      # Operational (non admin-manageable) features are not listed.
      assert_not_includes response.body, Irida::ExperimentalFeatureCatalog.fetch('compose_with_retry')[:description]
    end

    test 'system user enables a feature globally' do
      Flipper.disable(@feature_key)

      patch admin_feature_flags_update_global_state_path(feature_key: @feature_key, target_state: 'enabled')

      assert_redirected_to admin_feature_flags_path
      assert_equal I18n.t('active_admin.feature_flags.flash.global_enabled'), flash[:notice]
      assert_equal 'enabled', Irida::SystemFeatureFlagsCatalog.global_state(@feature_key)
    end

    test 'system user disables a feature globally' do
      Flipper.enable(@feature_key)

      patch admin_feature_flags_update_global_state_path(feature_key: @feature_key, target_state: 'disabled')

      assert_redirected_to admin_feature_flags_path
      assert_equal I18n.t('active_admin.feature_flags.flash.global_disabled'), flash[:notice]
      assert_equal 'disabled', Irida::SystemFeatureFlagsCatalog.global_state(@feature_key)
    end

    test 'a no-op global change reports no change' do
      Flipper.disable(@feature_key)

      patch admin_feature_flags_update_global_state_path(feature_key: @feature_key, target_state: 'disabled')

      assert_equal I18n.t('active_admin.feature_flags.flash.no_change'), flash[:notice]
    end

    test 'system user enables profile opt-in availability' do
      Flipper.disable(@feature_key)

      with_user_opt_in_features({}) do |settings|
        patch admin_feature_flags_update_opt_in_availability_path(feature_key: @feature_key, available: true)

        assert_redirected_to admin_feature_flags_path
        assert_equal I18n.t('active_admin.feature_flags.flash.opt_in_enabled'), flash[:notice]
        assert_equal 'all_users', settings.reload.opt_in_state(@feature_key)
      end
    end

    test 'system user disables profile opt-in availability' do
      Flipper.disable(@feature_key)

      with_user_opt_in_features(user_opt_in_feature_config) do |settings|
        patch admin_feature_flags_update_opt_in_availability_path(feature_key: @feature_key, available: false)

        assert_equal I18n.t('active_admin.feature_flags.flash.opt_in_disabled'), flash[:notice]
        assert_equal 'off', settings.reload.opt_in_state(@feature_key)
      end
    end

    test 'opt-in availability cannot change while the feature is enabled globally' do
      Flipper.enable(@feature_key)

      with_user_opt_in_features({}) do |settings|
        patch admin_feature_flags_update_opt_in_availability_path(feature_key: @feature_key, available: true)

        assert_redirected_to admin_feature_flags_path
        assert_equal I18n.t('active_admin.feature_flags.flash.errors.globally_enabled'), flash[:alert]
        assert_equal 'off', settings.reload.opt_in_state(@feature_key)
      end
    end

    test 'a feature that is not admin-manageable is rejected' do
      patch admin_feature_flags_update_global_state_path(feature_key: 'compose_with_retry', target_state: 'enabled')

      assert_equal I18n.t('active_admin.feature_flags.flash.errors.invalid_feature'), flash[:alert]
    end
  end
end
