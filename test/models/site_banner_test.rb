# frozen_string_literal: true

require 'test_helper'

class SiteBannerTest < ActiveSupport::TestCase
  test 'assigns singleton guard value to each record' do
    notification = SiteBanner.create!(enabled: false, style: :info, messages: {})

    assert notification.persisted?
    assert_equal SiteBanner::SINGLETON_GUARD, notification.singleton_guard
  end

  test 'new notifications are enabled by default' do
    notification = SiteBanner.new(style: :info, messages: localized_messages('Default enabled'))

    assert notification.enabled?
  end

  test 'enabling a new notification disables the previous enabled notification' do
    previous = SiteBanner.create!(style: :info, messages: localized_messages('Previous'))
    current = SiteBanner.create!(style: :warning, messages: localized_messages('Current'))

    assert_equal 2, SiteBanner.count
    assert_equal 1, SiteBanner.where(enabled: true).count
    assert_not previous.reload.enabled?
    assert current.reload.enabled?
    assert_equal current, SiteBanner.current
  end

  test 'current returns nil when no enabled notification exists' do
    SiteBanner.create!(enabled: false, style: :info, messages: {})

    assert_nil SiteBanner.current
  end

  test 'requires messages for all available locales when enabled' do
    notification = SiteBanner.new(enabled: true, style: :warning, messages: {})

    assert_not notification.valid?
    I18n.available_locales.each do |locale|
      assert(notification.errors[:messages].any? { |msg| msg.include?(locale.to_s) })
    end
  end

  test 'rejects partial locale coverage' do
    notification = SiteBanner.new(enabled: true, style: :info, messages: { en: 'English only' })

    assert_not notification.valid?
    assert(notification.errors[:messages].any? { |msg| msg.include?('fr') })
  end

  test 'only accepts canonical styles' do
    notification = SiteBanner.new(enabled: true, style: :notice, messages: { en: 'Hello', fr: 'Bonjour' })

    assert_not notification.valid?
    assert_includes notification.errors[:style], 'is not included in the list'
  end

  test 'message prefers current locale with default locale fallback' do
    notification = SiteBanner.new(
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
    notification = SiteBanner.new(enabled: true, style: :info, messages: { 'en' => 'English fallback' })

    message = I18n.with_locale(:fr) { notification.message }

    assert_equal 'English fallback', message
  end

  test 'active? requires enabled notification with message' do
    notification = SiteBanner.new(enabled: false, style: :info, messages: { en: 'Hello', fr: 'Bonjour' })
    assert_not notification.active?

    notification.enabled = true
    assert notification.active?
  end

  test 'skips locale validation when disabled' do
    notification = SiteBanner.new(enabled: false, style: :info, messages: {})

    assert notification.valid?
  end

  private

  def localized_messages(message)
    I18n.available_locales.index_with { |_locale| message }
  end
end
