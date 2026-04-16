# frozen_string_literal: true

require 'test_helper'

module Profiles
  module ExperimentalFeatures
    class OptInServiceTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @other_user = users(:jane_doe)
        Flipper.add(:data_grid_samples_table) unless Flipper.exist?(:data_grid_samples_table)
        Flipper.disable(:data_grid_samples_table)
        Flipper.disable_actor(:data_grid_samples_table, @user)
        Flipper.disable_actor(:data_grid_samples_table, @other_user)
      end

      def teardown
        Flipper.disable_actor(:data_grid_samples_table, @user)
        Flipper.disable_actor(:data_grid_samples_table, @other_user)
        Flipper.disable(:data_grid_samples_table)
      end

      test 'eligible_features returns allowlisted features with localized text and fallback' do
        service = OptInService.new(user: @user, locale: :fr, settings: feature_settings(allowlist: [@user.email]))

        features = service.eligible_features

        assert_equal 1, features.size
        assert_equal 'data_grid_samples_table', features.first[:key]
        assert_equal 'Data Grid Samples Table', features.first[:name]
        assert_equal 'Activer la nouvelle grille de donnees.', features.first[:description]
        assert_equal false, features.first[:enabled]
      end

      test 'eligible_features excludes non-allowlisted users' do
        service = OptInService.new(user: @other_user, settings: feature_settings(allowlist: [@user.email]))

        assert_empty service.eligible_features
      end

      test 'toggle enables and disables actor gate for eligible feature' do
        service = OptInService.new(user: @user, settings: feature_settings(allowlist: [@user.email]))

        enable_result = service.toggle(feature_key: 'data_grid_samples_table', enabled: true)

        assert_equal true, enable_result.success?
        assert_equal :ok, enable_result.status
        assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
        assert_equal true, enable_result.feature[:enabled]

        disable_result = service.toggle(feature_key: 'data_grid_samples_table', enabled: false)

        assert_equal true, disable_result.success?
        assert_equal :ok, disable_result.status
        assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
        assert_equal false, disable_result.feature[:enabled]
      end

      test 'toggle rejects unknown or non-allowlisted features' do
        service = OptInService.new(user: @other_user, settings: feature_settings(allowlist: [@user.email]))

        result = service.toggle(feature_key: 'data_grid_samples_table', enabled: true)

        assert_equal false, result.success?
        assert_equal :forbidden, result.status
        assert_equal :not_eligible, result.error_key
        assert_nil result.feature
      end

      test 'toggle returns unprocessable result when flipper raises' do
        flipper_singleton = nil
        original_enable_actor = nil
        service = OptInService.new(user: @user, settings: feature_settings(allowlist: [@user.email]))
        flipper_singleton = Flipper.singleton_class
        original_enable_actor = Flipper.method(:enable_actor)

        flipper_singleton.send(:define_method, :enable_actor) do |_feature_key, _actor|
          raise Flipper::Error, 'simulated flipper failure'
        end

        result = service.toggle(feature_key: 'data_grid_samples_table', enabled: true)

        assert_equal false, result.success?
        assert_equal :unprocessable_content, result.status
        assert_equal :error, result.error_key
        assert_equal false, result.feature[:enabled]
      ensure
        if flipper_singleton && original_enable_actor
          flipper_singleton.send(:define_method, :enable_actor,
                                 original_enable_actor)
        end
      end

      private

      def feature_settings(allowlist: 'all')
        {
          'data_grid_samples_table' => {
            'allowlist' => allowlist,
            'name' => {
              'en' => 'Data Grid Samples Table'
            },
            'description' => {
              'en' => 'Enable the new data grid for the samples table.',
              'fr' => 'Activer la nouvelle grille de donnees.'
            }
          }
        }
      end
    end
  end
end
