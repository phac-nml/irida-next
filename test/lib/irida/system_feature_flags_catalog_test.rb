# frozen_string_literal: true

require 'test_helper'

module Irida
  class SystemFeatureFlagsCatalogTest < ActiveSupport::TestCase
    setup do
      @user = users(:john_doe)
      Flipper.disable(:data_grid_samples_table)
    end

    test 'returns admin-manageable entries with runtime state' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        entry = SystemFeatureFlagsCatalog.fetch(:data_grid_samples_table)

        assert_equal 'data_grid_samples_table', entry[:key]
        assert_equal 'conditional', entry[:global_state]
        assert_equal 'all_users', entry[:opt_in_state]
        assert_equal 1, entry[:gate_summary]['actors']
      end
    end

    test 'reports allowlist opt-in state separately from all-user availability' do
      config = user_opt_in_feature_config(allowlist: [@user.email])

      with_user_opt_in_features(config) do
        assert_equal 'allowlist', SystemFeatureFlagsCatalog.fetch(:data_grid_samples_table)[:opt_in_state]
      end
    end

    test 'returns nil for operational features' do
      assert_nil SystemFeatureFlagsCatalog.fetch(:compose_with_retry)
    end

    test 'entries only include admin-manageable features with runtime state' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        entries = SystemFeatureFlagsCatalog.entries
        keys = entries.pluck(:key)

        assert_includes keys, 'data_grid_samples_table'
        assert_not_includes keys, 'compose_with_retry'

        entry = entries.find { |candidate| candidate[:key] == 'data_grid_samples_table' }
        assert_equal 'disabled', entry[:global_state]
        assert_equal 'all_users', entry[:opt_in_state]
        assert entry.key?(:gate_summary)
      end
    end

    test 'admin_manageable? reflects the feature configuration' do
      assert SystemFeatureFlagsCatalog.admin_manageable?(:data_grid_samples_table)
      assert_not SystemFeatureFlagsCatalog.admin_manageable?(:compose_with_retry)
      assert_not SystemFeatureFlagsCatalog.admin_manageable?(:unknown_feature)
    end

    test 'global_state reports enabled and disabled boolean gate states' do
      assert_equal 'disabled', SystemFeatureFlagsCatalog.global_state(:data_grid_samples_table)

      Flipper.enable(:data_grid_samples_table)
      assert_equal 'enabled', SystemFeatureFlagsCatalog.global_state(:data_grid_samples_table)
    end

    test 'gate_summary counts each configured gate type' do
      Flipper.enable_actor(:data_grid_samples_table, @user)
      Flipper.enable_percentage_of_actors(:data_grid_samples_table, 25)
      Flipper.enable_percentage_of_time(:data_grid_samples_table, 10)

      summary = SystemFeatureFlagsCatalog.gate_summary(:data_grid_samples_table)

      assert_equal 0, summary['boolean']
      assert_equal 1, summary['actors']
      assert_equal 0, summary['groups']
      assert_equal 25, summary['percentage_of_actors']
      assert_equal 10, summary['percentage_of_time']
      assert_equal 0, summary['expression']
    end
  end
end
