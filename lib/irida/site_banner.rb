# frozen_string_literal: true

require 'yaml'

module Irida
  # Reads persistent site banner messages from YAML.
  class SiteBanner
    DEFAULT_PATH = Rails.root.join('config/site_banner.yml')
    DEFAULT_TYPE = :warning

    TYPE_MAPPINGS = {
      alert: :danger,
      notice: :info,
      info: :info,
      warning: :warning,
      danger: :danger,
      success: :success
    }.freeze

    def self.messages(path: DEFAULT_PATH, locale: I18n.locale)
      new(path:, locale:).messages
    end

    def initialize(path: DEFAULT_PATH, locale: I18n.locale)
      @path = path
      @locale = locale
    end

    def messages
      payload = load_payload
      return [] unless payload.is_a?(Hash)

      entries = payload['messages'] || payload[:messages]
      return [] unless entries.is_a?(Array)

      entries.filter_map { |entry| normalize_entry(entry) }
    end

    private

    def load_payload
      return unless File.exist?(@path)

      YAML.safe_load_file(@path, aliases: true) || {}
    rescue Psych::SyntaxError => e
      log_error("Invalid YAML in #{@path}: #{e.class}: #{e.message}")
      nil
    rescue Errno::ENOENT, Errno::EACCES => e
      log_error("Unable to read banner config #{@path}: #{e.class}: #{e.message}")
      nil
    end

    def normalize_entry(entry)
      return unless entry.is_a?(Hash)
      return if entry.fetch('enabled', entry.fetch(:enabled, true)) == false

      message = resolve_message(entry['message'] || entry[:message])
      return if message.blank?

      {
        type: normalize_type(entry['type'] || entry[:type]),
        message:
      }
    end

    def resolve_message(raw_message)
      case raw_message
      when String
        raw_message
      when Hash
        localized_message(raw_message)
      end
    end

    def localized_message(messages)
      locale_key = @locale.to_s

      messages[locale_key] || messages[locale_key.to_sym] ||
        messages['en'] || messages[:en]
    end

    def normalize_type(raw_type)
      TYPE_MAPPINGS[raw_type.to_s.to_sym] || DEFAULT_TYPE
    end

    def log_error(message)
      Rails.logger.error(message)
    end
  end
end
