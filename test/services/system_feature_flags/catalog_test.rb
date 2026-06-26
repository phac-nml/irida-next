# frozen_string_literal: true

require 'test_helper'

module SystemFeatureFlags
  class CatalogTest < ActiveSupport::TestCase
    setup do
      @user = users(:john_doe)
      Flipper.disable(:data_grid_samples_table)
    end

    test 'returns admin-manageable entries with runtime state' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        entry = Catalog.fetch(:data_grid_samples_table)

        assert_equal 'data_grid_samples_table', entry[:key]
        assert_equal 'conditional', entry[:global_state]
        assert_equal 'all_users', entry[:opt_in_state]
        assert_equal 1, entry[:gate_summary]['actors']
      end
    end

    test 'reports allowlist opt-in state separately from all-user availability' do
      config = user_opt_in_feature_config(allowlist: [@user.email])

      with_user_opt_in_features(config) do
        assert_equal 'allowlist', Catalog.fetch(:data_grid_samples_table)[:opt_in_state]
      end
    end

    test 'returns nil for operational features' do
      assert_nil Catalog.fetch(:compose_with_retry)
    end
  end
end
