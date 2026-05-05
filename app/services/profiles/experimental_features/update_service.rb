# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Parses update params and maps opt-in toggle outcomes to controller-ready responses.
    class UpdateService
      Result = Struct.new(:success?, :status, :feature_key, :feature, :message)

      def initialize(user:, locale: I18n.locale, opt_in_service: nil)
        @user = user
        @locale = locale
        @opt_in_service = opt_in_service
      end

      def execute(params:)
        feature_key = parsed_feature_key(params[:feature_key])
        enabled = parsed_enabled(params[:enabled])

        return invalid_params_result(feature_key) unless feature_key && !enabled.nil?

        toggle_result = opt_in_service.toggle(feature_key:, enabled:)
        build_result(feature_key, toggle_result)
      end

      private

      attr_reader :user, :locale

      def build_result(feature_key, toggle_result)
        return ineligible_result(feature_key) if toggle_result.error_key == :not_eligible
        return toggle_error_result(feature_key, toggle_result.feature) unless toggle_result.success?

        Result.new(true, :ok, feature_key, toggle_result.feature, nil)
      end

      # i18n-tasks-use t('profiles.experimental_features.update.not_eligible')
      def ineligible_result(feature_key)
        Result.new(false, :forbidden, feature_key, nil, not_eligible_message)
      end

      # i18n-tasks-use t('profiles.experimental_features.update.error')
      def toggle_error_result(feature_key, feature)
        Result.new(false, :unprocessable_content, feature_key, feature, error_message)
      end

      def invalid_params_result(feature_key)
        Result.new(false, :unprocessable_content, feature_key, nil, error_message)
      end

      def not_eligible_message
        I18n.t('profiles.experimental_features.update.not_eligible', locale:)
      end

      def error_message
        I18n.t('profiles.experimental_features.update.error', locale:)
      end

      def parsed_feature_key(raw_feature_key)
        return nil unless raw_feature_key.is_a?(String)

        feature_key = raw_feature_key.strip
        return nil if feature_key.blank?
        return nil unless /\A[a-z0-9_]+\z/.match?(feature_key)

        feature_key
      end

      def parsed_enabled(raw_enabled)
        return true if raw_enabled == '1'
        return false if raw_enabled == '0'

        nil
      end

      def opt_in_service
        @opt_in_service ||= Profiles::ExperimentalFeatures::OptInService.new(user:, locale:)
      end
    end
  end
end
