# frozen_string_literal: true

require 'test_helper'

module SystemFeatureFlags
  class ChangeGlobalStateTest < ActiveSupport::TestCase
    setup do
      @administrator = users(:system_user)
      @user = users(:john_doe)
      Flipper.disable(:data_grid_samples_table)
    end

    test 'rejects non-system users without mutation' do
      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :enabled,
        user: @user
      ).execute

      assert result.failure?
      assert_equal :unauthorized, result.error
      assert_equal 'disabled', Catalog.global_state(:data_grid_samples_table)
    end

    test 'rejects non-admin-manageable feature keys' do
      result = ChangeGlobalState.new(
        feature_key: :compose_with_retry,
        target_state: :enabled,
        user: @administrator
      ).execute

      assert result.failure?
      assert_equal :invalid_feature, result.error
    end

    test 'rejects invalid target states' do
      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :conditional,
        user: @administrator
      ).execute

      assert result.failure?
      assert_equal :invalid_target_state, result.error
      assert_equal 'disabled', Catalog.global_state(:data_grid_samples_table)
    end

    test 'enables global state and clears conditional gates' do
      Flipper.enable_actor(:data_grid_samples_table, @user)

      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :enabled,
        user: @administrator
      ).execute

      assert result.success?
      assert_equal 'enabled', Catalog.global_state(:data_grid_samples_table)
      assert_empty Flipper[:data_grid_samples_table].actors_value
    end

    test 'disables global state' do
      Flipper.enable(:data_grid_samples_table)

      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :disabled,
        user: @administrator
      ).execute

      assert result.success?
      assert_equal 'disabled', Catalog.global_state(:data_grid_samples_table)
    end

    test 'returns no-op when already in target state' do
      Flipper.enable(:data_grid_samples_table)

      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :enabled,
        user: @administrator
      ).execute

      assert result.no_op?
    end

    test 'returns mutation_failed and keeps state consistent when the adapter raises' do
      Flipper.stubs(:enable).raises(Flipper::Error)

      result = ChangeGlobalState.new(
        feature_key: :data_grid_samples_table,
        target_state: :enabled,
        user: @administrator
      ).execute

      assert result.failure?
      assert_equal :mutation_failed, result.error
      assert_equal 'disabled', Catalog.global_state(:data_grid_samples_table)
    end
  end
end
