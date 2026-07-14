# frozen_string_literal: true

# database table for application settings. Only one row should be allowed in this table, and it should be created on
# application initialization.
class ApplicationSetting < ApplicationRecord
  USER_OPT_IN_FEATURES_JSON_SCHEMA = Rails.root.join('config/schemas/user_opt_in_features.json')

  validate :only_one_instance, on: :create
  validates :max_data_export_size_gigabytes,
            numericality: { only_integer: true, greater_than: 0 }
  validates :user_opt_in_features,
            json: { message: ->(errors) { errors }, schema: USER_OPT_IN_FEATURES_JSON_SCHEMA }

  def self.current
    first
  end

  def self.defaults
    {
      signup_enabled: true,
      password_authentication_enabled: true,
      cleanup_inactive_access_tokens_after_days: 30,
      require_personal_access_token_expiry: false,
      max_personal_access_token_lifetime_in_days: 365,
      max_data_export_size_gigabytes: 30
    }
  end

  def self.build_from_defaults(attributes = {})
    final_attributes = defaults.merge(attributes).stringify_keys.slice(*column_names)
    new(final_attributes)
  end

  def self.create_from_defaults
    build_from_defaults.tap(&:save)
  end

  def allow_signup?
    signup_enabled? && password_authentication_enabled?
  end

  def eligible_user_opt_in_features(user)
    (user_opt_in_features || {}).filter_map do |feature_key, feature_config|
      next unless flipper_feature_available?(feature_key)
      next unless user_eligible_for_opt_in_feature?(feature_config, user)

      user_opt_in_feature_payload(feature_key, user)
    end
  end

  def opt_in_feature_payload(feature_key, user)
    normalized_feature_key = feature_key.to_s
    return nil unless flipper_feature_available?(normalized_feature_key)

    feature_config = (user_opt_in_features || {})[normalized_feature_key]
    return nil if feature_config.blank?

    user_opt_in_feature_payload(normalized_feature_key, user)
  end

  private

  def flipper_feature_available?(feature_key)
    return false if feature_key.blank?

    Irida::ExperimentalFeatureCatalog.available?(feature_key)
  end

  def user_eligible_for_opt_in_feature?(feature_config, user)
    return false if feature_config.blank?

    allowlist = feature_config['allowlist']
    return true if allowlist == 'all'

    Array(allowlist).any? { |email| email.casecmp?(user.email) }
  end

  def user_opt_in_feature_payload(feature_key, user)
    catalog_feature = Irida::ExperimentalFeatureCatalog.fetch(feature_key)

    {
      key: feature_key.to_sym,
      name: catalog_feature[:name],
      description: catalog_feature[:description],
      enabled: user_opted_in_to_feature?(feature_key, user)
    }
  end

  def user_opted_in_to_feature?(feature_key, user)
    Flipper[feature_key.to_sym].actors_value.include?(user.flipper_id)
  end

  def only_one_instance
    return unless ApplicationSetting.count >= 1

    errors.add(:base, 'Only one instance of ApplicationSetting is allowed')
  end
end
