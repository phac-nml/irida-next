# frozen_string_literal: true

require 'test_helper'

class ApplicationSettingTest < ActiveSupport::TestCase
  setup do
    ApplicationSetting.delete_all
  end

  test 'only one instance allowed' do
    current_settings = ApplicationSetting.create_from_defaults
    assert current_settings.persisted?
    new_settings = ApplicationSetting.build_from_defaults
    assert_not new_settings.valid?
    assert_includes new_settings.errors[:base], 'Only one instance of ApplicationSetting is allowed'
  end

  test 'current returns the first instance' do
    ApplicationSetting.create_from_defaults
    current_settings = ApplicationSetting.current
    assert current_settings.present?
  end

  test 'defaults returns the default settings' do
    defaults = ApplicationSetting.defaults
    assert_equal true, defaults[:signup_enabled]
    assert_equal true, defaults[:password_authentication_enabled]
    assert_equal 30, defaults[:cleanup_inactive_access_tokens_after_days]
  end

  test 'build_from_defaults builds a new instance with defaults' do
    settings = ApplicationSetting.build_from_defaults
    assert settings.new_record?
    assert_equal true, settings.signup_enabled
    assert_equal true, settings.password_authentication_enabled
    assert_equal 30, settings.cleanup_inactive_access_tokens_after_days
  end

  test 'build_from_defaults allows overriding defaults' do
    settings = ApplicationSetting.build_from_defaults(signup_enabled: false)
    assert settings.new_record?
    assert_equal false, settings.signup_enabled
    assert_equal true, settings.password_authentication_enabled
    assert_equal 30, settings.cleanup_inactive_access_tokens_after_days
  end

  test 'create_from_defaults creates and saves a new instance with defaults' do
    settings = ApplicationSetting.create_from_defaults
    assert settings.persisted?
    assert_equal true, settings.signup_enabled
    assert_equal true, settings.password_authentication_enabled
    assert_equal 30, settings.cleanup_inactive_access_tokens_after_days
  end

  test '#signup_enabled? returns the value of signup_enabled' do
    settings = ApplicationSetting.create_from_defaults
    assert settings.signup_enabled?
    settings.update(signup_enabled: false)
    assert_not settings.signup_enabled?
  end

  test '#password_authentication_enabled? returns the value of password_authentication_enabled' do
    settings = ApplicationSetting.create_from_defaults
    assert settings.password_authentication_enabled?
    settings.update(password_authentication_enabled: false)
    assert_not settings.password_authentication_enabled?
  end

  test '#cleanup_inactive_access_tokens_after_days returns the value of cleanup_inactive_access_tokens_after_days' do
    settings = ApplicationSetting.create_from_defaults
    assert_equal 30, settings.cleanup_inactive_access_tokens_after_days
    settings.update(cleanup_inactive_access_tokens_after_days: 60)
    assert_equal 60, settings.cleanup_inactive_access_tokens_after_days
  end
end
