# frozen_string_literal: true

# Singleton global notification shown in application layouts.
class GlobalNotification < ApplicationRecord
  SINGLETON_GUARD = 'global'

  enum :style, {
    info: 'info',
    warning: 'warning',
    danger: 'danger',
    success: 'success'
  }, validate: true

  validates :singleton_guard, inclusion: { in: [SINGLETON_GUARD] }, uniqueness: true
  validate :all_locale_messages_present, if: :enabled?

  before_validation :set_singleton_guard

  def self.instance
    find_or_initialize_by(singleton_guard: SINGLETON_GUARD)
  end

  def self.instance!
    find_or_create_by!(singleton_guard: SINGLETON_GUARD)
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

    missing.each { |locale| errors.add(:messages, "must include a message for #{locale}") }
  end

  def set_singleton_guard
    self.singleton_guard = SINGLETON_GUARD
  end
end
