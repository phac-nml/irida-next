# frozen_string_literal: true

module SystemFeatureFlags
  # Applies profile-level actor gate toggles while enforcing opt-in availability under lock.
  #
  # Does not check admin_manageable? — relies on UpdateOptInAvailability enforcing
  # that only admin-manageable features can have opt-in config entries.
  class UpdateUserOptIn < BaseFeatureFlagService
    def initialize(feature_key:, enabled:, user:)
      super()
      @feature_key = feature_key.to_s
      @enabled = enabled
      @user = user
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return failure(:invalid_enabled, feature_key:) unless [true, false].include?(enabled)

      with_feature_lock(feature_key:, settings:) do
        abort_mutation!(:not_eligible) unless settings.opt_in_feature_eligible_for_user?(feature_key, user)

        @feature_state_before_mutation = snapshot_feature_state(feature_key)
        if enabled
          Flipper.enable_actor(feature_key.to_sym, user)
        else
          Flipper.disable_actor(feature_key.to_sym, user)
        end
      end

      success(feature_key:)
    rescue AbortMutation => e
      failure(e.error, feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      # Defensive: transaction rollback restores DB state, but this ensures
      # Flipper's in-memory cache is consistent with the database.
      restore_feature_state!(feature_key, @feature_state_before_mutation) unless @feature_state_before_mutation.nil?
      log_mutation_failure('Unable to change user experimental feature opt-in', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :enabled, :user

    def settings
      @settings ||= Irida::CurrentSettings.current_application_settings
    end
  end
end
