# frozen_string_literal: true

# Audit record for administrator changes to admin-managed experimental feature flags.
class SystemFeatureFlagChange < ApplicationRecord
  ACTIONS = %w[
    enable_global
    disable_global
    enable_opt_in
    disable_opt_in
  ].freeze

  GLOBAL_STATES = %w[enabled disabled conditional].freeze
  OPT_IN_STATES = %w[off all_users allowlist].freeze

  belongs_to :administrator, class_name: 'User'

  validates :feature_key, :environment, presence: true
  validates :action, inclusion: { in: ACTIONS }
  validates :old_global_state, :new_global_state, inclusion: { in: GLOBAL_STATES }
  validates :old_opt_in_state, :new_opt_in_state, inclusion: { in: OPT_IN_STATES }
  validate :feature_is_admin_manageable

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  private

  def feature_is_admin_manageable
    return if SystemFeatureFlags::Catalog.admin_manageable?(feature_key)

    errors.add(:feature_key, :invalid)
  end
end
