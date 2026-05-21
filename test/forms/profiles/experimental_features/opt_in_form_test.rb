# frozen_string_literal: true

require 'test_helper'

module Profiles
  module ExperimentalFeatures
    class OptInFormTest < ActiveSupport::TestCase
      setup do
        @user = users(:john_doe)

        ApplicationSetting.delete_all
      end

      test 'is invalid when feature_key is blank' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: '', enabled: true)

          assert_not form.valid?
          assert_predicate form.errors[:feature_key], :any?
        end
      end

      test 'is invalid when feature_key format is invalid' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'bad-key!', enabled: true)

          assert_not form.valid?
          assert_predicate form.errors[:feature_key], :any?
        end
      end

      test 'is invalid when enabled is not a boolean-like value' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: 'yes')

          assert_not form.valid?
          assert_includes form.errors.details[:enabled].pluck(:error), :inclusion
        end
      end

      test 'is invalid when user is not on allowlist' do
        config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

        with_user_opt_in_features(config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_not form.valid?
          assert_includes form.errors.details[:feature_key].pluck(:error), :not_eligible
        end
      end

      test 'is invalid for unknown feature key' do
        config = user_opt_in_feature_config(feature_key: :unknown_experiment, allowlist: 'all')

        with_user_opt_in_features(config) do
          form = build_form(feature_key: 'unknown_experiment', enabled: true)

          assert_not form.valid?
          assert_includes form.errors.details[:feature_key].pluck(:error), :invalid
          assert_not Flipper.exist?(:unknown_experiment)
        end
      end

      test 'is valid for eligible feature' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_predicate form, :valid?
        end
      end

      test 'matches allowlist emails case-insensitively' do
        config = user_opt_in_feature_config(allowlist: [@user.email.upcase])

        with_user_opt_in_features(config) do
          form = build_form(feature_key: 'data_grid_samples_table', enabled: true)

          assert_predicate form, :valid?
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
