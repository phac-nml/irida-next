# frozen_string_literal: true

module SystemFeatureFlags
  # Changes profile opt-in availability for an admin-manageable feature.
  class ChangeOptInAvailability < MutationService
    def initialize(feature_key:, available:, user:)
      super()
      @feature_key = feature_key.to_s
      @available = available
      @user = user
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return failure(:unauthorized, feature_key:) unless system_user?(user)
      return failure(:invalid_feature, feature_key:) unless Catalog.admin_manageable?(feature_key)
      return failure(:invalid_availability, feature_key:) unless [true, false].include?(available)
      return failure(:globally_enabled, feature_key:) if Catalog.global_state(feature_key) == 'enabled'

      # Pre-lock optimization: skip lock if nothing would change.
      # May be stale under concurrency; the in-lock re-check guarantees correctness.
      return no_op(feature_key:) if no_op?(Catalog.opt_in_state(feature_key))

      applied = with_feature_lock(feature_key:, settings:) do
        abort_mutation!(:globally_enabled) if Catalog.global_state(feature_key) == 'enabled'

        next if no_op?(Catalog.opt_in_state(feature_key))

        @previous_opt_in_features = settings.user_opt_in_features.deep_dup
        @feature_state_before_mutation = snapshot_feature_state(feature_key)
        available ? enable_opt_in : disable_opt_in
        true
      end

      return no_op(feature_key:) if applied.nil?

      success(feature_key:)
    rescue AbortMutation => e
      failure(e.error, feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      restore_after_mutation_failure!
      log_mutation_failure('Unable to change experimental feature opt-in availability', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :available, :user

    # No-op when the requested change matches the current state:
    # - available=true is a no-op if opt-in is already configured (state != 'off')
    # - available=false is a no-op if opt-in is already disabled (state == 'off')
    def no_op?(current_opt_in_state)
      if available
        current_opt_in_state != 'off'
      else
        current_opt_in_state == 'off'
      end
    end

    def enable_opt_in
      features = settings.user_opt_in_features.deep_dup || {}
      features[feature_key] = { 'allowlist' => 'all' }
      settings.update!(user_opt_in_features: features)
    end

    def disable_opt_in
      features = settings.user_opt_in_features.deep_dup || {}
      features.delete(feature_key)
      settings.update!(user_opt_in_features: features)

      # Revoke actor gates via Flipper API to stay consistent with adapter
      # internals (memoization, instrumentation). One query per actor.
      feature = Flipper[feature_key.to_sym]
      feature.actors_value.each do |flipper_actor_id|
        feature.disable_actor(Flipper::Actor.new(flipper_actor_id))
      end
    end

    def settings
      @settings ||= Irida::CurrentSettings.current_application_settings
    end

    def restore_after_mutation_failure!
      return unless @previous_opt_in_features || @feature_state_before_mutation

      settings.update!(user_opt_in_features: @previous_opt_in_features)
      restore_feature_state!(feature_key, @feature_state_before_mutation)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      log_mutation_failure('Unable to restore feature state after opt-in mutation failure', e)
    end
  end
end
