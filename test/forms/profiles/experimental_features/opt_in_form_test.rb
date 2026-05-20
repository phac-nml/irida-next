# frozen_string_literal: true

require 'test_helper'

module Profiles
  module ExperimentalFeatures
    class OptInFormTest < ActiveSupport::TestCase
      setup do
        @user = users(:john_doe)

        ApplicationSetting.delete_all
        Flipper.disable_actor(:data_grid_samples_table, @user)
      end

      test 'save is invalid when feature_key is blank' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: '', enabled: true)

          assert_not form.save
          assert_predicate form.errors[:feature_key], :any?
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'save is invalid when feature_key format is invalid' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'bad-key!', enabled: true)

          assert_not form.save
          assert_predicate form.errors[:feature_key], :any?
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'save is invalid when user is not on allowlist' do
        config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

        with_user_opt_in_features(config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_not form.save
          assert_includes form.errors.details[:feature_key].pluck(:error), :not_eligible
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'save is invalid for unknown feature key' do
        config = user_opt_in_feature_config(feature_key: :unknown_experiment, allowlist: 'all')

        with_user_opt_in_features(config) do
          form = build_form(feature_key: 'unknown_experiment', enabled: true)

          assert_not form.save
          assert_includes form.errors.details[:feature_key].pluck(:error), :not_eligible
          assert_not Flipper.exist?(:unknown_experiment)
        end
      end

      test 'save enables actor gate for eligible feature' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert form.save
          assert_predicate form.result, :success?
          assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      ensure
        Flipper.disable_actor(:data_grid_samples_table, @user)
      end

      test 'save disables actor gate for eligible feature' do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: false)

          assert form.save
          assert_predicate form.result, :success?
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'save adds flipper_error when toggle fails' do
        Flipper.expects(:enable_actor).raises(Flipper::Error, 'adapter failed')
        Rails.logger.expects(:error).with(regexp_matches(/adapter failed/))

        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_not form.save
          assert_includes form.errors.details[:base].pluck(:error), :flipper_error
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'param_key is opt_in_form for form_with' do
        assert_equal 'opt_in_form', OptInForm.model_name.param_key
      end

      private

      def build_form(**attributes)
        OptInForm.new(user: @user, **attributes)
      end
    end
  end
end
