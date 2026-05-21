# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Service used to list and toggle user-managed experimental feature opt-ins.
    class OptInService < BaseService
      attr_reader :opt_in_form

      def initialize(user, opt_in_form = nil, settings: Irida::CurrentSettings.current_application_settings)
        super(user)

        @opt_in_form = opt_in_form
        @settings = settings
      end

      def eligible_features
        user_opt_in_features.filter_map do |feature_key, feature_config|
          next unless feature_available?(feature_key)
          next unless user_eligible?(feature_config)

          feature_payload(feature_key, feature_config)
        end
      end

      def execute
        return false unless opt_in_form&.valid?

        update_actor_gate(opt_in_form.feature_key, opt_in_form.enabled)
        true
      rescue Flipper::Error => e
        Rails.logger.error("Unable to update experimental feature opt-in: #{e.message}")
        opt_in_form.errors.add(:base, :flipper_error)
        false
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
    end
  end
end
