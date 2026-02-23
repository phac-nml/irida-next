# frozen_string_literal: true

require 'test_helper'

class GlobalNotificationTest < ActiveSupport::TestCase
  test '.instance! creates the singleton row' do
    notification = GlobalNotification.instance!

    assert notification.persisted?
    assert_equal GlobalNotification::SINGLETON_GUARD, notification.singleton_guard
  end

  test 'enforces singleton at model validation level' do
    GlobalNotification.instance!.update!(enabled: true, style: :info, message_en: 'Hello')

    duplicate = GlobalNotification.new(
      singleton_guard: GlobalNotification::SINGLETON_GUARD,
      enabled: true,
      style: :warning,
      message_en: 'Second message'
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:singleton_guard], 'has already been taken'
  end

  test 'requires at least one localized message' do
    notification = GlobalNotification.new(enabled: true, style: :warning)

    assert_not notification.valid?
    assert_includes notification.errors[:message], "can't be blank"
  end

  test 'only accepts canonical styles' do
    notification = GlobalNotification.new(enabled: true, style: :notice, message_en: 'Hello')

    assert_not notification.valid?
    assert_includes notification.errors[:style], 'is not included in the list'
  end

  test 'message prefers current locale with default locale fallback' do
    notification = GlobalNotification.new(
      enabled: true,
      style: :danger,
      message_en: 'English text',
      message_fr: 'Texte francais'
    )

    fr_message = I18n.with_locale(:fr) { notification.message }
    en_message = I18n.with_locale(:en) { notification.message }

    assert_equal 'Texte francais', fr_message
    assert_equal 'English text', en_message
  end

  test 'message falls back to default locale when current locale is unavailable' do
    notification = GlobalNotification.new(enabled: true, style: :info, message_en: 'English fallback')

    message = I18n.with_locale(:fr) { notification.message }

    assert_equal 'English fallback', message
  end

  test 'active? requires enabled notification with message' do
    notification = GlobalNotification.new(enabled: false, style: :info, message_en: 'Hello')
    assert_not notification.active?

    notification.enabled = true
    assert notification.active?
  end
end
