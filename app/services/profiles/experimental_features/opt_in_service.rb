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

        result = update_user_opt_in
        return true if result.success?

        opt_in_form.errors.add(:feature_key, :not_eligible) if result.error == :not_eligible
        false
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
        settings.opt_in_feature_payload(feature_key, current_user)
      end

      def update_user_opt_in
        SystemFeatureFlags::ChangeUserOptIn.new(
          feature_key: opt_in_form.feature,
          enabled: opt_in_form.enabled?,
          user: current_user
        ).execute
      end
    end
  end
end
