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

      attr_reader :user, :settings, :result

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

      def save # rubocop:disable Naming/PredicateMethod -- ActiveRecord-style form API
        return false unless valid?

        @result = opt_in_service.toggle(feature_key, enabled)
        return true if @result.success?

        errors.add(:base, :flipper_error) if @result.error == :flipper_error
        false
      end

      private

      def opt_in_service
        @opt_in_service ||= OptInService.new(user, settings:)
      end

      def enabled_must_be_boolean_value
        return if ENABLED_VALUES.include?(@enabled_input)

        errors.add(:enabled, :inclusion)
      end

      def feature_must_be_eligible
        return if feature_key.blank?

        unless opt_in_service.manageable_feature?(feature_key)
          errors.add(:feature_key, :invalid)
          return
        end

        return if opt_in_service.eligible?(feature_key)

        errors.add(:feature_key, :not_eligible)
      end
    end
  end
end
