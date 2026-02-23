# frozen_string_literal: true

# Singleton global notification shown in application layouts.
class GlobalNotification < ApplicationRecord
  SINGLETON_GUARD = 'global'
  MESSAGE_ATTRIBUTES = {
    en: :message_en,
    fr: :message_fr
  }.freeze

  enum :style, {
    info: 'info',
    warning: 'warning',
    danger: 'danger',
    success: 'success'
  }, validate: true

  validates :singleton_guard, inclusion: { in: [SINGLETON_GUARD] }, uniqueness: true
  validate :at_least_one_message_present, if: :enabled?

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
    locale_message(locale) || locale_message(I18n.default_locale)
  end

  private

  def at_least_one_message_present
    return if MESSAGE_ATTRIBUTES.values.any? { |attr| public_send(attr).present? }

    errors.add(:message, :blank)
  end

  def locale_message(locale)
    attribute = MESSAGE_ATTRIBUTES[locale.to_sym]
    return if attribute.nil?

    public_send(attribute).presence
  end

  def set_singleton_guard
    self.singleton_guard = SINGLETON_GUARD
  end
end
