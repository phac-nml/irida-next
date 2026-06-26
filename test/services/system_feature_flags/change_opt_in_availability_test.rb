# frozen_string_literal: true

require 'test_helper'

module SystemFeatureFlags
  class ChangeOptInAvailabilityTest < ActiveSupport::TestCase
    setup do
      @administrator = users(:system_user)
      @user = users(:john_doe)
      Flipper.disable(:data_grid_samples_table)
    end

    test 'enables all-user opt-in availability when no entry exists' do
      with_user_opt_in_features({}) do |settings|
        result = ChangeOptInAvailability.call(
          feature_key: :data_grid_samples_table,
          available: true,
          actor: @administrator
        )

        assert result.success?
        assert_equal 'all_users', Catalog.opt_in_state(:data_grid_samples_table)
        assert_equal({ 'allowlist' => 'all' }, settings.reload.user_opt_in_features['data_grid_samples_table'])
        assert_equal 'enable_opt_in', result.change.action
        assert_equal 'off', result.change.old_opt_in_state
        assert_equal 'all_users', result.change.new_opt_in_state
      end
    end

    test 'preserves existing email allowlist when enabling availability' do
      config = user_opt_in_feature_config(allowlist: [@user.email])

      with_user_opt_in_features(config) do |settings|
        result = ChangeOptInAvailability.call(
          feature_key: :data_grid_samples_table,
          available: true,
          actor: @administrator
        )

        assert result.no_op?
        assert_equal [@user.email], settings.reload.user_opt_in_features.dig('data_grid_samples_table', 'allowlist')
        assert_equal 0, SystemFeatureFlagChange.count
      end
    end

    test 'disables opt-in availability and revokes actor gates only' do
      with_user_opt_in_features(user_opt_in_feature_config) do |settings|
        Flipper.enable_actor(:data_grid_samples_table, @user)
        Flipper.enable_percentage_of_time(:data_grid_samples_table, 10)

        result = ChangeOptInAvailability.call(
          feature_key: :data_grid_samples_table,
          available: false,
          actor: @administrator
        )

        assert result.success?
        assert_nil settings.reload.user_opt_in_features['data_grid_samples_table']
        assert_empty Flipper[:data_grid_samples_table].actors_value
        assert_equal 10, Flipper[:data_grid_samples_table].percentage_of_time_value
        assert_equal 1, result.change.cleared_gate_summary['actors']
      end
    end

    test 'rejects opt-in availability changes while feature is globally enabled' do
      with_user_opt_in_features({}) do
        Flipper.enable(:data_grid_samples_table)

        result = ChangeOptInAvailability.call(
          feature_key: :data_grid_samples_table,
          available: true,
          actor: @administrator
        )

        assert result.failure?
        assert_equal :globally_enabled, result.error
        assert_equal 0, SystemFeatureFlagChange.count
      end
    end

    test 'rolls back settings and actor revocation when audit write fails' do
      with_user_opt_in_features(user_opt_in_feature_config) do |settings|
        Flipper.enable_actor(:data_grid_samples_table, @user)
        SystemFeatureFlagChange.stubs(:create!).raises(ActiveRecord::RecordInvalid)

        result = ChangeOptInAvailability.call(
          feature_key: :data_grid_samples_table,
          available: false,
          actor: @administrator
        )

        assert result.failure?
        assert_equal :mutation_failed, result.error
        assert_equal({ 'allowlist' => 'all' }, settings.reload.user_opt_in_features['data_grid_samples_table'])
        assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    end
  end
end
