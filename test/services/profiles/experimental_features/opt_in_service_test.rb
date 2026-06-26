# frozen_string_literal: true

require 'test_helper'

module Profiles
  module ExperimentalFeatures
    class OptInServiceTest < ActiveSupport::TestCase
      setup do
        @user = users(:john_doe)

        ApplicationSetting.delete_all
        Flipper.disable_actor(:data_grid_samples_table, @user)
        Flipper.disable_actor(:v2_datepicker, @user)
      end

      test 'execute enables actor gate for a valid form' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert OptInService.new(@user, form).execute
          assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      ensure
        Flipper.disable_actor(:data_grid_samples_table, @user)
      end

      test 'execute disables actor gate for a valid form' do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: false)

          assert OptInService.new(@user, form).execute
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'execute returns false when the form is invalid' do
        form = mock('opt_in_form')
        form.expects(:valid?).returns(false)
        SystemFeatureFlags::ChangeUserOptIn.expects(:new).never

        assert_not OptInService.new(@user, form).execute
      end

      test 'execute adds not_eligible when actor mutation is rejected by runtime guard' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)
          not_eligible_result = SystemFeatureFlags::Result.new(
            status: :failure, change: nil, entry: nil, error: :not_eligible
          )
          mock_service = mock('change_user_opt_in')
          mock_service.stubs(:execute).returns(not_eligible_result)
          SystemFeatureFlags::ChangeUserOptIn.stubs(:new).returns(mock_service)

          assert_not OptInService.new(@user, form).execute
          assert_includes form.errors.details[:feature_key].pluck(:error), :not_eligible
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'execute adds flipper_error when toggle fails' do
        Flipper.expects(:enable_actor).raises(Flipper::Error, 'adapter failed')
        Rails.logger.expects(:error).with(regexp_matches(/adapter failed/))

        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_not OptInService.new(@user, form).execute
          assert_includes form.errors.details[:base].pluck(:error), :flipper_error
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'eligible_features returns configured eligible payloads' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          feature = OptInService.new(@user).eligible_features.first

          assert_equal :data_grid_samples_table, feature[:key]
          assert_equal 'Data Grid Samples Table', feature[:name]
          assert_equal 'Enable the new data grid for the samples table.', feature[:description]
          assert_equal false, feature[:enabled]
        end
      end

      test 'feature returns nil for unknown feature key' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          feature = OptInService.new(@user).feature('unknown_feature')

          assert_nil feature
        end
      end

      test 'feature returns nil for ineligible user by default' do
        config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

        with_user_opt_in_features(config) do
          feature = OptInService.new(@user).feature('data_grid_samples_table')

          assert_nil feature
        end
      end

      test 'feature returns payload for configured ineligible feature when include_ineligible is true' do
        config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

        with_user_opt_in_features(config) do
          feature = OptInService.new(@user).feature('data_grid_samples_table', include_ineligible: true)

          assert_equal :data_grid_samples_table, feature[:key]
          assert_equal 'Data Grid Samples Table', feature[:name]
          assert_equal 'Enable the new data grid for the samples table.', feature[:description]
          assert_equal false, feature[:enabled]
        end
      end

      private

      def build_form(**attributes)
        OptInForm.new(user: @user, **attributes)
      end
    end
  end
end
