# frozen_string_literal: true

require 'test_helper'
require Rails.root.join('db/migrate/20260619150000_normalize_user_opt_in_feature_settings')

class NormalizeUserOptInFeatureSettingsTest < ActiveSupport::TestCase
  setup do
    ApplicationSetting.delete_all
    @settings = ApplicationSetting.create_from_defaults
  end

  test 'retains feature keys and allowlists while removing display copy' do
    migration_settings.update!(
      user_opt_in_features: {
        'data_grid_samples_table' => {
          'allowlist' => ['USER@example.com'],
          'name' => { 'en' => 'Legacy name' },
          'description' => { 'en' => 'Legacy description' }
        }
      }
    )

    NormalizeUserOptInFeatureSettings.new.up

    assert_equal(
      { 'data_grid_samples_table' => { 'allowlist' => ['USER@example.com'] } },
      @settings.reload.user_opt_in_features
    )
  end

  test 'fails when a configured opt-in feature has no localized catalog entry' do
    migration_settings.update!(
      user_opt_in_features: { 'unknown_experiment' => { 'allowlist' => 'all' } }
    )

    error = assert_raises(ActiveRecord::MigrationError) do
      NormalizeUserOptInFeatureSettings.new.up
    end

    assert_includes error.message, 'unknown_experiment'
  end

  private

  def migration_settings
    NormalizeUserOptInFeatureSettings::ApplicationSettingRecord.find(@settings.id)
  end
end
