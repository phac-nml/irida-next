# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Service used to toggle user-managed experimental feature opt-ins.
    class OptInService < BaseService
      attr_reader :opt_in_form

      def initialize(user, opt_in_form = nil)
        super(user)

        @opt_in_form = opt_in_form
      end

      def eligible_features
        settings.eligible_user_opt_in_features(current_user)
      end

      def feature(feature_key, include_ineligible: false)
        normalized_feature_key = feature_key.to_s
        return nil if normalized_feature_key.blank?

        feature = eligible_features.find { |item| item[:key] == normalized_feature_key.to_sym }
        return feature if feature.present?
        return nil unless include_ineligible

        feature_payload(normalized_feature_key)
      end

      def execute
        return false unless opt_in_form&.valid?

        update_actor_gate
        true
      rescue Flipper::Error => e
        Rails.logger.error("Unable to update experimental feature opt-in: #{e.message}")
        opt_in_form.errors.add(:base, :flipper_error)
        false
      end

      private

      def settings
        @settings ||= Irida::CurrentSettings.current_application_settings
      end

      def feature_payload(feature_key)
        return nil unless FLIPPER_FEATURE_CONFIG['features'].key?(feature_key)

        feature_config = (settings.user_opt_in_features || {})[feature_key]
        return nil if feature_config.blank?

        {
          key: feature_key.to_sym,
          name: localized_value(feature_config['name']),
          description: localized_value(feature_config['description']),
          enabled: Flipper[feature_key.to_sym].actors_value.include?(current_user.flipper_id)
        }
      end

      def localized_value(translations)
        translations[I18n.locale.to_s].presence || translations['en']
      end

      def update_actor_gate
        if opt_in_form.enabled?
          Flipper.enable_actor(opt_in_form.feature, current_user)
        else
          Flipper.disable_actor(opt_in_form.feature, current_user)
        end
      end
    end
  end
end
