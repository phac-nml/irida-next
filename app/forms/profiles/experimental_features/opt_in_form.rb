# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Form object for a single experimental-feature opt-in toggle submission.
    class OptInForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      ENABLED_VALUES = [true, false, 'true', 'false', '1', '0', 1, 0].freeze

      attribute :feature_key, :string
      attribute :enabled, :boolean

      validates :feature_key, presence: true, format: { with: /\A[a-zA-Z0-9_]+\z/ }
      validate :enabled_must_be_boolean_value
      validate :feature_must_be_eligible

      attr_reader :user, :settings

      def self.model_name
        ActiveModel::Name.new(self, nil, 'OptInForm')
      end

      def initialize(user:, settings: Irida::CurrentSettings.current_application_settings, **attributes)
        @user = user
        @settings = settings
        super(**attributes)
      end

      def enabled=(value)
        @enabled_input = value
        super
      end

      def feature
        feature_key.to_sym
      end

      def enabled?
        enabled
      end

      private

      def enabled_must_be_boolean_value
        return if ENABLED_VALUES.include?(@enabled_input)

        errors.add(:enabled, :inclusion)
      end

      def feature_must_be_eligible
        return if feature_key.blank?

        unless manageable_feature?
          errors.add(:feature_key, :invalid)
          return
        end

        return if eligible_user?

        errors.add(:feature_key, :not_eligible)
      end

      def manageable_feature?
        feature_available? && feature_config.present?
      end

      def eligible_user?
        return false if feature_config.blank?

        allowlist = feature_config['allowlist']
        return true if allowlist == 'all'

        Array(allowlist).any? { |email| email.casecmp?(user.email) }
      end

      def feature_available?
        Irida::ExperimentalFeatureCatalog.available?(feature_key)
      end

      def feature_config
        @feature_config ||= (settings.user_opt_in_features || {})[feature_key]
      end
    end
  end
end
