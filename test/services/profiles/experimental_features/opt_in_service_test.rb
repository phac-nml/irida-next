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
        Flipper.expects(:enable_actor).never
        Flipper.expects(:disable_actor).never

        assert_not OptInService.new(@user, form).execute
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

      private

      def build_form(**attributes)
        OptInForm.new(user: @user, **attributes)
      end
    end
  end
end
