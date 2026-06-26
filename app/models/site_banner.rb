# frozen_string_literal: true

# Site banners shown in application layouts.
class SiteBanner < ApplicationRecord
  SINGLETON_GUARD = 'global'

  enum :style, {
    info: 'info',
    warning: 'warning',
    danger: 'danger',
    success: 'success'
  }, validate: true

  scope :enabled, -> { where(enabled: true) }
  attribute :enabled, :boolean, default: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at enabled id style updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  validates :singleton_guard, inclusion: { in: [SINGLETON_GUARD] }
  validate :all_locale_messages_present, if: :enabled?

  before_validation :set_singleton_guard
  before_save :disable_other_enabled_banners, if: :enabled?

  def self.current
    enabled.order(updated_at: :desc, id: :desc).first
  end

  def active?
    enabled? && message.present?
  end

  def message(locale: I18n.locale)
    messages[locale.to_s].presence || messages[I18n.default_locale.to_s].presence
  end

  private

  def all_locale_messages_present
    missing = I18n.available_locales.select { |locale| messages[locale.to_s].blank? }
    return if missing.empty?

    missing.each { |locale| errors.add(:messages, :missing_locale_message, locale_code: locale) }
  end

  def set_singleton_guard
    self.singleton_guard = SINGLETON_GUARD
  end

  def disable_other_enabled_banners
    # Serialize banner enable transitions so the unique partial index is not hit under concurrent writes.
    self.class.connection.execute("LOCK TABLE #{self.class.quoted_table_name} IN SHARE ROW EXCLUSIVE MODE")
    self.class.enabled.where.not(id: id).update_all(enabled: false, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
