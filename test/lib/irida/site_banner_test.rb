# frozen_string_literal: true

require 'test_helper'

module Irida
  class SiteBannerTest < ActiveSupport::TestCase
    setup do
      @tmp_dir = Dir.mktmpdir
      @banner_path = File.join(@tmp_dir, 'site_banner.yml')
    end

    teardown do
      FileUtils.remove_entry(@tmp_dir)
    end

    test 'returns an empty array when file is missing' do
      messages = SiteBanner.messages(path: @banner_path)

      assert_equal [], messages
    end

    test 'returns enabled entries in order' do
      write_banner <<~YAML
        messages:
          - type: info
            message: "First"
          - type: warning
            message: "Second"
      YAML

      messages = SiteBanner.messages(path: @banner_path)

      assert_equal(%i[info warning], messages.pluck(:type))
      assert_equal(%w[First Second], messages.pluck(:message))
    end

    test 'filters out disabled entries' do
      write_banner <<~YAML
        messages:
          - enabled: false
            type: danger
            message: "Do not render"
          - message: "Render me"
      YAML

      messages = SiteBanner.messages(path: @banner_path)

      assert_equal 1, messages.length
      assert_equal 'Render me', messages.first[:message]
    end

    test 'filters out disabled entries when enabled uses yaml falsey strings' do
      write_banner <<~YAML
        messages:
          - enabled: "false"
            message: "Do not render"
          - enabled: "0"
            message: "Do not render either"
          - enabled: "off"
            message: "Skip this one too"
          - enabled: "true"
            message: "Render me"
      YAML

      messages = SiteBanner.messages(path: @banner_path)

      assert_equal 1, messages.length
      assert_equal 'Render me', messages.first[:message]
    end

    test 'defaults type to warning when type is missing' do
      write_banner <<~YAML
        messages:
          - message: "No type"
      YAML

      messages = SiteBanner.messages(path: @banner_path)

      assert_equal :warning, messages.first[:type]
    end

    test 'resolves localized message by current locale with english fallback' do
      write_banner <<~YAML
        messages:
          - type: danger
            message:
              en: "English text"
              fr: "Texte francais"
      YAML

      fr_message = I18n.with_locale(:fr) { SiteBanner.messages(path: @banner_path).first[:message] }
      en_message = I18n.with_locale(:en) { SiteBanner.messages(path: @banner_path).first[:message] }

      assert_equal 'Texte francais', fr_message
      assert_equal 'English text', en_message
    end

    test 'falls back to default locale when locale key is missing' do
      write_banner <<~YAML
        messages:
          - message:
              en: "English fallback"
      YAML

      message = I18n.with_locale(:fr) { SiteBanner.messages(path: @banner_path).first[:message] }

      assert_equal 'English fallback', message
    end

    test 'falls back to configured default locale when locale key is missing' do
      write_banner <<~YAML
        messages:
          - message:
              fr: "Texte par defaut"
      YAML

      I18n.stubs(:default_locale).returns(:fr)

      message = I18n.with_locale(:en) { SiteBanner.messages(path: @banner_path).first[:message] }

      assert_equal 'Texte par defaut', message
    end

    test 'skips localized message without current locale or english fallback' do
      write_banner <<~YAML
        messages:
          - type: info
            message:
              es: "Solo espanol"
      YAML

      messages = I18n.with_locale(:fr) { SiteBanner.messages(path: @banner_path) }

      assert_equal [], messages
    end

    test 'logs error and returns empty array when yaml is invalid' do
      write_banner <<~YAML
        messages:
          - type: warning
            message: "oops"
          - [invalid
      YAML

      original_logger = Rails.logger
      logged_messages = []

      begin
        mock_logger = Object.new
        mock_logger.define_singleton_method(:error) { |message| logged_messages << message }
        Rails.logger = mock_logger

        messages = SiteBanner.messages(path: @banner_path)

        assert_equal [], messages
      ensure
        Rails.logger = original_logger
      end

      assert(logged_messages.any? { |message| message.include?('Invalid YAML in') })
    end

    test 'logs error and returns empty array when yaml parser raises psych exception' do
      original_logger = Rails.logger
      logged_messages = []

      begin
        mock_logger = Object.new
        mock_logger.define_singleton_method(:error) { |message| logged_messages << message }
        Rails.logger = mock_logger

        YAML.expects(:safe_load_file).with(@banner_path).raises(Psych::Exception.new('boom'))

        messages = SiteBanner.messages(path: @banner_path)

        assert_equal [], messages
      ensure
        Rails.logger = original_logger
      end

      assert(logged_messages.any? { |message| message.include?('Invalid YAML in') })
    end

    private

    def write_banner(contents)
      File.write(@banner_path, contents)
    end
  end
end
