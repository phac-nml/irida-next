# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Handles eligibility and actor-level Flipper toggling for profile opt-ins.
    class OptInService
      Result = Struct.new(:success?, :status, :feature_key, :feature, :error_key)

      def initialize(user:, locale: I18n.locale, settings: nil)
        @user = user
        @locale = locale.to_s
        @settings = normalize_settings(settings)
      end

      def eligible_features
        settings.filter_map do |feature_key, feature_config|
          next unless user_eligible?(feature_config)

          feature_hash(feature_key:, enabled: actor_opted_in?(feature_key), feature_config:)
        end
      end

      def feature_config_for(feature_key)
        settings[feature_key]
      end

      def toggle(feature_key:, enabled:)
        feature_config = feature_config_for(feature_key)
        return ineligible_result(feature_key) unless feature_config && user_eligible?(feature_config)

        toggle_actor_gate(feature_key, enabled)
        success_result(feature_key, enabled, feature_config)
      rescue Flipper::Error => e
        Rails.logger.error(
          'Profiles::ExperimentalFeatures::OptInService toggle failed for ' \
          "#{feature_key}: #{e.message}"
        )
        error_result(feature_key, enabled, feature_config)
      end

      private

      attr_reader :user, :locale, :settings

      def ineligible_result(feature_key)
        Result.new(false, :forbidden, feature_key, nil, :not_eligible)
      end

      def success_result(feature_key, enabled, feature_config)
        Result.new(true, :ok, feature_key, feature_hash(feature_key:, enabled:, feature_config:), nil)
      end

      def error_result(feature_key, enabled, feature_config)
        Result.new(false, :unprocessable_content, feature_key,
                   feature_hash(feature_key:, enabled: !enabled, feature_config:), :error)
      end

      def toggle_actor_gate(feature_key, enabled)
        if enabled
          Flipper.enable_actor(feature_key.to_sym, user)
        else
          Flipper.disable_actor(feature_key.to_sym, user)
        end
      end

      def feature_hash(feature_key:, enabled:, feature_config:)
        {
          key: feature_key,
          enabled:,
          name: localized_text(feature_config['name']),
          description: localized_text(feature_config['description'])
        }
      end

      def localized_text(translations)
        return nil unless translations.is_a?(Hash)

        translations[locale] || translations['en']
      end

      def actor_opted_in?(feature_key)
        # Intentional: actor gate state reflects user opt-in only, unlike Flipper.enabled?
        Flipper[feature_key.to_sym].actors_value.include?(user.flipper_id)
      end

      def user_eligible?(feature_config)
        return false unless feature_config.is_a?(Hash)

        allowlist = feature_config['allowlist']
        return true if allowlist == 'all'
        return false unless allowlist.is_a?(Array)
        return false if normalized_user_email.blank?

        allowlist.any? { |email| email.to_s.strip.casecmp?(normalized_user_email) }
      end

      def normalized_user_email
        @normalized_user_email ||= user&.email.to_s.strip.downcase
      end

      def normalize_settings(explicit_settings)
        source = explicit_settings || Irida::CurrentSettings.current_application_settings.user_opt_in_features
        source.is_a?(Hash) ? source : {}
      end
    end
  end
end
