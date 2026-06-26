# frozen_string_literal: true

module SystemFeatureFlags
  # Applies profile-level actor gate toggles while enforcing opt-in availability under lock.
  class ChangeActorOptIn < MutationService
    class << self
      def call(feature_key:, enabled:, actor:)
        new(feature_key:, enabled:, actor:).call
      end
    end

    def initialize(feature_key:, enabled:, actor:)
      super()
      @feature_key = feature_key.to_s
      @enabled = enabled
      @actor = actor
    end

    def call # rubocop:disable Metrics/AbcSize
      return :invalid_enabled unless [true, false].include?(enabled)

      with_feature_lock(feature_key:, settings:) do
        abort_mutation!(:not_eligible) unless settings.opt_in_feature_eligible_for_user?(feature_key, actor)

        if enabled
          Flipper.enable_actor(feature_key.to_sym, actor)
        else
          Flipper.disable_actor(feature_key.to_sym, actor)
        end
      end

      :success
    rescue AbortMutation => e
      e.error
    end

    private

    attr_reader :feature_key, :enabled, :actor

    def settings
      @settings ||= Irida::CurrentSettings.current_application_settings
    end
  end
end
