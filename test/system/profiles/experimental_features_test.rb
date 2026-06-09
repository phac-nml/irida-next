# frozen_string_literal: true

require 'application_system_test_case'

module Profiles
  class ExperimentalFeaturesTest < ApplicationSystemTestCase
    include UserOptInFeaturesTestHelper

    setup do
      @user = users(:john_doe)
      login_as @user
    end

    test 'toggle shows pending state, restores focus, and clears success text' do
      with_user_opt_in_features(user_opt_in_feature_config) do
        visit profile_experimental_features_path

        page.execute_script <<~JS
          const form = document.querySelector("#experimental-feature-data_grid_samples_table form");
          const originalRequestSubmit = form.requestSubmit.bind(form);
          form.requestSubmit = function() {
            setTimeout(() => originalRequestSubmit(), 300);
          };
        JS

        within '#experimental-feature-data_grid_samples_table' do
          find("label.group[for='experimental-feature-data_grid_samples_table-switch']").click
        end

        assert_selector '#experimental-feature-data_grid_samples_table-status',
                        text: I18n.t('profiles.experimental_features.update.saving')

        assert_selector '#experimental-feature-data_grid_samples_table-status',
                        text: I18n.t('profiles.experimental_features.update.success')
        assert_equal 'experimental-feature-data_grid_samples_table-switch',
                     page.evaluate_script('document.activeElement.id')

        assert_no_selector '#experimental-feature-data_grid_samples_table-status',
                           text: I18n.t('profiles.experimental_features.update.success'),
                           wait: 5
      end
    ensure
      Flipper.disable_actor(:data_grid_samples_table, @user)
    end
  end
end
