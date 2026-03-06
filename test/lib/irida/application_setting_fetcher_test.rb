# frozen_string_literal: true

require 'test_helper'

class ApplicationSettingFetcherTest < ActiveSupport::TestCase
  test 'current_application_settings returns the current settings' do
    settings = ApplicationSetting.create_from_defaults
    assert_equal settings, Irida::ApplicationSettingFetcher.current_application_settings
  end

  test 'current_application_settings returns the same instance on subsequent calls' do
    settings = ApplicationSetting.create_from_defaults
    assert_equal settings, Irida::ApplicationSettingFetcher.current_application_settings
    assert_equal settings, Irida::ApplicationSettingFetcher.current_application_settings
  end

  test 'current_application_settings returns a new instance if no settings exist' do
    assert_nil ApplicationSetting.current
    settings = Irida::ApplicationSettingFetcher.current_application_settings
    assert_not_nil ApplicationSetting.current
    assert settings.persisted?
    assert_equal ApplicationSetting.current, settings
  end

  test 'current_application_settings? returns true when settings exist' do
    ApplicationSetting.create_from_defaults
    assert Irida::ApplicationSettingFetcher.current_application_settings?
  end

  test 'current_application_settings? returns false when no settings exist' do
    assert_not Irida::ApplicationSettingFetcher.current_application_settings?
  end
end
