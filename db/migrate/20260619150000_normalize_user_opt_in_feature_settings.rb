# frozen_string_literal: true

# Removes display copy from user opt-in settings after it moved to config/features.yml.
class NormalizeUserOptInFeatureSettings < ActiveRecord::Migration[8.1]
  # Migration-local model that bypasses the application model's evolving validations.
  class ApplicationSettingRecord < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    feature_catalog = YAML.safe_load(Rails.root.join('config/features.yml').read).fetch('features')

    ApplicationSettingRecord.find_each do |settings|
      normalized_features = settings.user_opt_in_features.to_h.each_with_object({}) do |(feature_key, config), result|
        ensure_localized_catalog_entry!(feature_catalog, feature_key)
        result[feature_key] = { 'allowlist' => config.fetch('allowlist') }
      end

      settings.update!(user_opt_in_features: normalized_features)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Feature display copy cannot be restored from application settings'
  end

  private

  def ensure_localized_catalog_entry!(feature_catalog, feature_key)
    config = feature_catalog[feature_key]
    return if localized_copy?(config&.fetch('name', nil)) && localized_copy?(config&.fetch('description', nil))

    message = "Feature #{feature_key.inspect} must define English and French name and description values"
    raise ActiveRecord::MigrationError, "#{message} in config/features.yml"
  end

  def localized_copy?(value)
    value.is_a?(Hash) && value.values_at('en', 'fr').all?(&:present?)
  end
end
