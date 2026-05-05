# frozen_string_literal: true

require 'test_helper'

module Profiles
  module ExperimentalFeatures
    class UpdateServiceTest < ActiveSupport::TestCase
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

      test 'execute enables actor for valid params' do
        service = UpdateService.new(user: @user, opt_in_service: opt_in_service_for(@user))

        result = service.execute(params: { feature_key: 'data_grid_samples_table', enabled: '1' })

        assert_equal true, result.success?
        assert_equal :ok, result.status
        assert_equal 'data_grid_samples_table', result.feature_key
        assert_equal true, result.feature[:enabled]
        assert_nil result.message
        assert Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
      end

      test 'execute rejects malformed feature key params' do
        service = UpdateService.new(user: @user, opt_in_service: opt_in_service_for(@user))

        result = service.execute(params: { feature_key: 'data-grid-samples-table', enabled: '1' })

        assert_equal false, result.success?
        assert_equal :unprocessable_content, result.status
        assert_nil result.feature
        assert_equal I18n.t('profiles.experimental_features.update.error'), result.message
        assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
      end

      test 'execute rejects ineligible feature' do
        service = UpdateService.new(user: @other_user, opt_in_service: opt_in_service_for(@other_user))

        result = service.execute(params: { feature_key: 'data_grid_samples_table', enabled: '1' })

        assert_equal false, result.success?
        assert_equal :forbidden, result.status
        assert_equal 'data_grid_samples_table', result.feature_key
        assert_nil result.feature
        assert_equal I18n.t('profiles.experimental_features.update.not_eligible'), result.message
        assert_not Flipper[:data_grid_samples_table].actors_value.include?(@other_user.flipper_id)
      end

      test 'execute returns unprocessable result when flipper raises' do
        service = UpdateService.new(user: @user, opt_in_service: opt_in_service_for(@user))

        Flipper.stubs(:enable_actor).raises(Flipper::Error, 'simulated flipper failure')

        begin
          result = service.execute(params: { feature_key: 'data_grid_samples_table', enabled: '1' })

          assert_equal false, result.success?
          assert_equal :unprocessable_content, result.status
          assert_equal 'data_grid_samples_table', result.feature_key
          assert_equal false, result.feature[:enabled]
          assert_equal I18n.t('profiles.experimental_features.update.error'), result.message
          assert_not Flipper[:data_grid_samples_table].actors_value.include?(@user.flipper_id)
        ensure
          Flipper.unstub(:enable_actor)
        end
      end

      private

      def opt_in_service_for(user)
        OptInService.new(user:, settings: feature_settings)
      end

      def feature_settings
        {
          'data_grid_samples_table' => {
            'allowlist' => [@user.email],
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
