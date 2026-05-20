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

      test 'eligible_features returns features with all-user allowlist' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          features = OptInService.new(@user).eligible_features

          assert_equal [:data_grid_samples_table], features.pluck(:key)
          assert_equal 'Data Grid Samples Table', features.first[:name]
          assert_equal 'Enable the new data grid for the samples table.', features.first[:description]
          assert_not features.first[:enabled]
        end
      end

      test 'eligible_features uses case-insensitive email allowlist matching' do
        config = user_opt_in_feature_config(allowlist: [@user.email.upcase])

        with_user_opt_in_features(config) do
          features = OptInService.new(@user).eligible_features

          assert_equal [:data_grid_samples_table], features.pluck(:key)
        end
      end

      test 'eligible_features excludes users missing from email allowlist' do
        config = user_opt_in_feature_config(allowlist: [users(:jane_doe).email])

        with_user_opt_in_features(config) do
          assert_empty OptInService.new(@user).eligible_features
        end
      end

      test 'eligible_features excludes feature keys missing from flipper feature config' do
        config = user_opt_in_feature_config(feature_key: :unknown_experiment, allowlist: 'all')

        with_user_opt_in_features(config) do
          assert_empty OptInService.new(@user).eligible_features
        end
      end

      test 'eligible_features reports actor-specific enabled state' do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        with_user_opt_in_features(user_opt_in_feature_config) do
          feature = OptInService.new(@user).eligible_features.first

          assert feature[:enabled]
        end
      ensure
        Flipper.disable_actor(:data_grid_samples_table, @user)
      end

      test 'eligible_features localizes feature metadata with english fallback' do
        I18n.with_locale(:fr) do
          with_user_opt_in_features(user_opt_in_feature_config) do
            feature = OptInService.new(@user).eligible_features.first

            assert_equal 'Tableau de donnees des echantillons', feature[:name]
            assert_equal "Activer la nouvelle grille de donnees pour le tableau d'echantillons.",
                         feature[:description]
          end
        end
      end

      test 'toggle enables actor gate for eligible feature' do
        with_user_opt_in_features(user_opt_in_feature_config) do
          result = OptInService.new(@user).toggle(:data_grid_samples_table, true)

          assert result.success?
          assert_nil result.error
          assert_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
          assert result.feature[:enabled]
        end
      ensure
        Flipper.disable_actor(:data_grid_samples_table, @user)
      end

      test 'toggle disables actor gate for eligible feature' do
        Flipper.enable_actor(:data_grid_samples_table, @user)

        with_user_opt_in_features(user_opt_in_feature_config) do
          result = OptInService.new(@user).toggle('data_grid_samples_table', false)

          assert result.success?
          assert_nil result.error
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
          assert_not result.feature[:enabled]
        end
      end

      test 'toggle catches and logs flipper errors' do
        Flipper.expects(:enable_actor).raises(Flipper::Error, 'adapter failed')
        Rails.logger.expects(:error).with(regexp_matches(/adapter failed/))

        with_user_opt_in_features(user_opt_in_feature_config) do
          result = OptInService.new(@user).toggle(:data_grid_samples_table, true)

          assert_not result.success?
          assert_equal :flipper_error, result.error
          assert_not_includes Flipper[:data_grid_samples_table].actors_value, @user.flipper_id
        end
      end

      test 'eligible? returns true only for available features allowlisted for user' do
        config = user_opt_in_feature_config.merge(
          user_opt_in_feature_config(feature_key: :v2_datepicker, allowlist: [users(:jane_doe).email])
        )

        with_user_opt_in_features(config) do
          service = OptInService.new(@user)

          assert service.eligible?(:data_grid_samples_table)
          assert_not service.eligible?(:v2_datepicker)
          assert_not service.eligible?(:unknown_experiment)
        end
      end
    end
  end
end
