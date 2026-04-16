# frozen_string_literal: true

# database table for application settings. Only one row should be allowed in this table, and it should be created on
# application initialization.
class ApplicationSetting < ApplicationRecord
  USER_OPT_IN_FEATURES_JSON_SCHEMA = Rails.root.join('config/schemas/user_opt_in_features.json')

  validate :only_one_instance, on: :create
  validates :user_opt_in_features,
            json: { message: ->(errors) { errors }, schema: USER_OPT_IN_FEATURES_JSON_SCHEMA }

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
end
