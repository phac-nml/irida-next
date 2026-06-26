# frozen_string_literal: true

module SystemFeatureFlags
  # Applies profile-level actor gate toggles while enforcing opt-in availability under lock.
  #
  # User-initiated opt-in toggles are not audited in system_feature_flag_changes.
  # Only admin mutations (global state, opt-in availability) create audit records.
  #
  # Does not check admin_manageable? — relies on ChangeOptInAvailability enforcing
  # that only admin-manageable features can have opt-in config entries.
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
      return failure(:invalid_enabled, feature_key:) unless [true, false].include?(enabled)

      with_feature_lock(feature_key:, settings:) do
        abort_mutation!(:not_eligible) unless settings.opt_in_feature_eligible_for_user?(feature_key, actor)

        if enabled
          Flipper.enable_actor(feature_key.to_sym, actor)
        else
          Flipper.disable_actor(feature_key.to_sym, actor)
        end
      end

      success(change: nil, feature_key:)
    rescue AbortMutation => e
      failure(e.error, feature_key:)
    end

    private

    attr_reader :feature_key, :enabled, :actor

    def settings
      @settings ||= Irida::CurrentSettings.current_application_settings
    end
  end
end
