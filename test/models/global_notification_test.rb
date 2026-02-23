# frozen_string_literal: true

require 'test_helper'

class GlobalNotificationTest < ActiveSupport::TestCase
  test '.instance! creates the singleton row' do
    notification = GlobalNotification.instance!

    assert notification.persisted?
    assert_equal GlobalNotification::SINGLETON_GUARD, notification.singleton_guard
  end

  test 'enforces singleton at model validation level' do
    GlobalNotification.instance!.update!(enabled: true, style: :info, messages: { en: 'Hello', fr: 'Bonjour' })

    duplicate = GlobalNotification.new(
      singleton_guard: GlobalNotification::SINGLETON_GUARD,
      enabled: true,
      style: :warning,
      messages: { en: 'Second', fr: 'Deuxième' }
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:singleton_guard], 'has already been taken'
  end

  test 'requires messages for all available locales when enabled' do
    notification = GlobalNotification.new(enabled: true, style: :warning, messages: {})

    assert_not notification.valid?
    I18n.available_locales.each do |locale|
      assert(notification.errors[:messages].any? { |msg| msg.include?(locale.to_s) })
    end
  end

  test 'rejects partial locale coverage' do
    notification = GlobalNotification.new(enabled: true, style: :info, messages: { en: 'English only' })

    assert_not notification.valid?
    assert(notification.errors[:messages].any? { |msg| msg.include?('fr') })
  end

  test 'only accepts canonical styles' do
    notification = GlobalNotification.new(enabled: true, style: :notice, messages: { en: 'Hello', fr: 'Bonjour' })

    assert_not notification.valid?
    assert_includes notification.errors[:style], 'is not included in the list'
  end

  test 'message prefers current locale with default locale fallback' do
    notification = GlobalNotification.new(
      enabled: true,
      style: :danger,
      messages: { 'en' => 'English text', 'fr' => 'Texte francais' }
    )

    fr_message = I18n.with_locale(:fr) { notification.message }
    en_message = I18n.with_locale(:en) { notification.message }

    assert_equal 'Texte francais', fr_message
    assert_equal 'English text', en_message
  end

  test 'message falls back to default locale when current locale is unavailable' do
    notification = GlobalNotification.new(enabled: true, style: :info, messages: { 'en' => 'English fallback' })

    message = I18n.with_locale(:fr) { notification.message }

    assert_equal 'English fallback', message
  end

  test 'active? requires enabled notification with message' do
    notification = GlobalNotification.new(enabled: false, style: :info, messages: { en: 'Hello', fr: 'Bonjour' })
    assert_not notification.active?

    notification.enabled = true
    assert notification.active?
  end

  test 'skips locale validation when disabled' do
    notification = GlobalNotification.new(enabled: false, style: :info, messages: {})

    assert notification.valid?
  end
end
