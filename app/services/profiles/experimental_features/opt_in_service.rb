# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Service used to list and toggle user-managed experimental feature opt-ins.
    class OptInService < BaseService
      # Value object returned from feature opt-in toggle attempts.
      class Result
        attr_reader :feature, :error

        def initialize(success:, feature: nil, error: nil)
          @success = success
          @feature = feature
          @error = error
        end

        def success?
          @success
        end
      end

      def initialize(user, params = {}, settings: Irida::CurrentSettings.current_application_settings)
        super(user, params)

        @settings = settings
      end

      def eligible_features
        user_opt_in_features.filter_map do |feature_key, feature_config|
          next unless feature_available?(feature_key)
          next unless user_eligible?(feature_config)

          feature_payload(feature_key, feature_config)
        end
      end

      def toggle(feature_key, enabled)
        normalized_feature_key = feature_key.to_s
        feature_config = user_opt_in_features[normalized_feature_key]

        return ineligible_result unless eligible_config?(normalized_feature_key, feature_config)

        update_actor_gate(normalized_feature_key, enabled)

        success_result(normalized_feature_key, feature_config)
      rescue Flipper::Error => e
        Rails.logger.error("Unable to update experimental feature opt-in: #{e.message}")

        flipper_error_result(normalized_feature_key, feature_config)
      end

      def eligible?(feature_key)
        feature_config = user_opt_in_features[feature_key.to_s]

        eligible_config?(feature_key.to_s, feature_config)
      end

      private

      attr_reader :settings

      def user_opt_in_features
        settings.user_opt_in_features || {}
      end

      def feature_available?(feature_key)
        return false if feature_key.blank?

        FLIPPER_FEATURE_CONFIG['features'].key?(feature_key)
      end

      def eligible_config?(feature_key, feature_config)
        feature_available?(feature_key) && user_eligible?(feature_config)
      end

      def user_eligible?(feature_config)
        return false if feature_config.blank?

        allowlist = feature_config['allowlist']
        return true if allowlist == 'all'

        Array(allowlist).any? { |email| email.casecmp?(current_user.email) }
      end

      def feature_payload(feature_key, feature_config)
        {
          key: feature_key.to_sym,
          name: localized_config_value(feature_config['name']),
          description: localized_config_value(feature_config['description']),
          enabled: actor_opted_in?(feature_key)
        }
      end

      def localized_config_value(translations)
        translations[I18n.locale.to_s].presence || translations['en']
      end

      def actor_opted_in?(feature_key)
        Flipper[feature_key.to_sym].actors_value.include?(current_user.flipper_id)
      end

      def update_actor_gate(feature_key, enabled)
        if enabled
          Flipper.enable_actor(feature_key.to_sym, current_user)
        else
          Flipper.disable_actor(feature_key.to_sym, current_user)
        end
      end

      def success_result(feature_key, feature_config)
        Result.new(success: true, feature: feature_payload(feature_key, feature_config))
      end

      def ineligible_result
        Result.new(success: false, error: :not_eligible)
      end

      def flipper_error_result(feature_key, feature_config)
        Result.new(
          success: false,
          feature: feature_payload(feature_key, feature_config),
          error: :flipper_error
        )
      end
    end
  end
end
