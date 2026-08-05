# frozen_string_literal: true

require 'test_helper'

module SystemFeatureFlags
  class UpdateUserOptInTest < ActiveSupport::TestCase
    setup do
      @user = users(:john_doe)
      Flipper.disable(:data_grid_samples_table)
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'enables actor gate when user is eligible and opt-in is available' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        result = UpdateUserOptIn.new(feature_key: :data_grid_samples_table, enabled: true, user: @user).execute

        assert result.success?
        assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'disables actor gate when user is eligible and opt-in is available' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        result = UpdateUserOptIn.new(feature_key: :data_grid_samples_table, enabled: false, user: @user).execute

        assert result.success?
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    end

    test 'returns not_eligible when user is not in feature allowlist' do
      config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

      with_user_opt_in_features(config) do
        result = UpdateUserOptIn.new(feature_key: :data_grid_samples_table, enabled: true, user: @user).execute

        assert result.failure?
        assert_equal :not_eligible, result.error
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    end

    test 'returns not_eligible when opt-in availability has been disabled' do
      with_user_opt_in_features({}) do
        result = UpdateUserOptIn.new(feature_key: :data_grid_samples_table, enabled: true, user: @user).execute

        assert result.failure?
        assert_equal :not_eligible, result.error
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    end

    test 'returns mutation_failed and keeps Flipper state consistent when the adapter raises' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        Flipper.expects(:enable_actor).raises(ActiveRecord::StatementInvalid)

        result = UpdateUserOptIn.new(feature_key: :data_grid_samples_table, enabled: true, user: @user).execute

        assert result.failure?
        assert_equal :mutation_failed, result.error
        assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end

    test 'racing admin disable and user opt-in keeps actor gate revoked' do
      with_user_opt_in_features(user_opt_in_feature_config) do |settings|
        ready = Queue.new
        start = Queue.new
        user_result = nil
        admin_result = nil

        user_thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << :user
            start.pop
            user_result = UpdateUserOptIn.new(
              feature_key: :data_grid_samples_table,
              enabled: true,
              user: @user
            ).execute
          end
        end

        admin_thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << :admin
            start.pop
            admin_result = UpdateOptInAvailability.new(
              feature_key: :data_grid_samples_table,
              available: false,
              user: users(:system_user)
            ).execute
          end
        end

        2.times { ready.pop }
        2.times { start << true }
        [user_thread, admin_thread].each(&:join)

        assert user_result.success? || user_result.error == :not_eligible
        assert admin_result.success?
        assert_nil settings.reload.user_opt_in_features['data_grid_samples_table']
        assert_equal 'off', Irida::SystemFeatureFlagsCatalog.opt_in_state(:data_grid_samples_table)
        assert_empty Flipper[:data_grid_samples_table].actors_value
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end
  end
end
