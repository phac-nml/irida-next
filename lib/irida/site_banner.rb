# frozen_string_literal: true

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
      payload = load_payload&.deep_symbolize_keys
      return [] unless payload

      entries = payload[:messages]
      return [] unless entries.is_a?(Array)

      entries.filter_map { |entry| normalize_entry(entry) }
    end

    private

    def load_payload
      result = YAML.safe_load_file(@path)
      result.is_a?(Hash) ? result : nil
    rescue Errno::ENOENT
      nil
    rescue Psych::Exception => e
      log_error("Invalid YAML in #{@path}: #{e.class}: #{e.message}")
      nil
    rescue Errno::EACCES => e
      log_error("Unable to read banner config #{@path}: #{e.class}: #{e.message}")
      nil
    end

    def normalize_entry(entry)
      return unless entry.is_a?(Hash)
      return unless enabled?(entry)

      message = resolve_message(entry[:message])
      return if message.blank?

      {
        type: normalize_type(entry[:type]),
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
      messages[@locale.to_sym] || messages[I18n.default_locale.to_sym]
    end

    def enabled?(entry)
      enabled = entry.fetch(:enabled, true)
      ActiveModel::Type::Boolean.new.cast(enabled) != false
    end

    def normalize_type(raw_type)
      TYPE_MAPPINGS[raw_type.to_s.to_sym] || DEFAULT_TYPE
    end

    def log_error(message)
      Rails.logger.error(message)
    end
  end
end
