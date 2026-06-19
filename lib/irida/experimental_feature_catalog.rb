# frozen_string_literal: true

module Irida
  # Read-only interface for feature metadata declared in config/features.yml.
  module ExperimentalFeatureCatalog
    class << self
      def entries(locale: I18n.locale)
        feature_config.map do |key, config|
          entry(key, config, locale)
        end
      end

      def admin_entries(locale: I18n.locale)
        entries(locale: locale).select { |feature| feature[:admin_manageable] }
      end

      def fetch(feature_key, locale: I18n.locale)
        normalized_key = feature_key.to_s
        config = feature_config[normalized_key]
        return if config.nil?

        entry(normalized_key, config, locale)
      end

      def available?(feature_key)
        feature_config.key?(feature_key.to_s)
      end

      def descriptions(locale: I18n.locale)
        entries(locale: locale).to_h { |feature| [feature[:key], feature[:description]] }
      end

      private

      def feature_config
        FLIPPER_FEATURE_CONFIG.fetch('features')
      end

      def entry(key, config, locale)
        {
          key: key,
          name: localized_value(config['name'], locale),
          description: localized_value(config['description'], locale),
          admin_manageable: config['admin_manageable'] == true
        }
      end

      def localized_value(value, locale)
        return value unless value.is_a?(Hash)

        value[locale.to_s].presence || value['en']
      end
    end
  end
end
