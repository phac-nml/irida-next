# frozen_string_literal: true

# database table for application settings. Only one row should be allowed in this table, and it should be created on
# application initialization.
class ApplicationSetting < ApplicationRecord
  validate :only_one_instance, on: :create
  validate :validate_user_opt_in_features

  def self.current
    first
  end

  def self.defaults
    {
      signup_enabled: true,
      password_authentication_enabled: true,
      cleanup_inactive_access_tokens_after_days: 30
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

  private

  def only_one_instance
    return unless ApplicationSetting.count >= 1

    errors.add(:base, 'Only one instance of ApplicationSetting is allowed')
  end

  def validate_user_opt_in_features
    return if user_opt_in_features.nil?

    unless user_opt_in_features.is_a?(Hash)
      errors.add(:user_opt_in_features, 'must be a hash')
      return
    end

    user_opt_in_features.each do |feature_key, feature_config|
      validate_feature_key(feature_key)
      validate_feature_config(feature_key, feature_config)
    end
  end

  def validate_feature_key(feature_key)
    return if feature_key.to_s.match?(/\A[a-z0-9_]+\z/)

    errors.add(:user_opt_in_features, "contains invalid feature key: #{feature_key.inspect}")
  end

  def validate_feature_config(feature_key, feature_config)
    unless feature_config.is_a?(Hash)
      errors.add(:user_opt_in_features, "#{feature_key} must be a hash")
      return
    end

    validate_allowlist(feature_key, feature_config['allowlist'])
    validate_localized_text(feature_key, 'name', feature_config['name'])
    validate_localized_text(feature_key, 'description', feature_config['description'])
  end

  def validate_allowlist(feature_key, allowlist)
    return if allowlist == 'all'
    return if allowlist.is_a?(Array) && allowlist.all? { |value| value.to_s.strip.present? }

    errors.add(:user_opt_in_features, "#{feature_key}.allowlist must be 'all' or an array of emails")
  end

  def validate_localized_text(feature_key, field_name, value)
    unless value.is_a?(Hash)
      errors.add(:user_opt_in_features, "#{feature_key}.#{field_name} must be a locale hash")
      return
    end

    return if value['en'].to_s.strip.present?

    errors.add(:user_opt_in_features, "#{feature_key}.#{field_name}.en must be present")
  end
end
