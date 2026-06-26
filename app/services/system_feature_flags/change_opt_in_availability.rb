# frozen_string_literal: true

module SystemFeatureFlags
  # Changes profile opt-in availability for an admin-manageable feature and audits the result.
  class ChangeOptInAvailability < MutationService
    AVAILABILITY_ACTIONS = {
      true => 'enable_opt_in',
      false => 'disable_opt_in'
    }.freeze

    class << self
      def call(feature_key:, available:, actor:)
        new(feature_key:, available:, actor:).call
      end
    end

    def initialize(feature_key:, available:, actor:)
      super()
      @feature_key = feature_key.to_s
      @available = available
      @actor = actor
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return failure(:unauthorized, feature_key:) unless system_actor?(actor)
      return failure(:invalid_feature, feature_key:) unless Catalog.admin_manageable?(feature_key)
      return failure(:invalid_availability, feature_key:) unless [true, false].include?(available)
      return failure(:globally_enabled, feature_key:) if Catalog.global_state(feature_key) == 'enabled'

      old_global_state = Catalog.global_state(feature_key)
      old_opt_in_state = Catalog.opt_in_state(feature_key)
      return no_op(feature_key:) if no_op?(old_opt_in_state)

      change = with_feature_lock(feature_key:, settings:) do
        abort_mutation!(:globally_enabled) if Catalog.global_state(feature_key) == 'enabled'

        @previous_opt_in_features = settings.user_opt_in_features.deep_dup
        @feature_state_before_mutation = snapshot_feature_state(feature_key)
        cleared_gate_summary = available ? {} : { 'actors' => Catalog.actor_gate_count(feature_key) }
        available ? enable_opt_in : disable_opt_in

        create_change!(
          actor:,
          feature_key:,
          action: AVAILABILITY_ACTIONS.fetch(available),
          old_global_state:,
          new_global_state: Catalog.global_state(feature_key),
          old_opt_in_state:,
          new_opt_in_state: Catalog.opt_in_state(feature_key),
          cleared_gate_summary:
        )
      end

      success(change:, feature_key:)
    rescue AbortMutation => e
      failure(e.error, feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      restore_after_audit_failure!
      log_mutation_failure('Unable to change experimental feature opt-in availability', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :available, :actor

    def no_op?(old_opt_in_state)
      return old_opt_in_state != 'off' if available

      old_opt_in_state == 'off'
    end

    def enable_opt_in
      features = settings.user_opt_in_features.deep_dup || {}
      features[feature_key] ||= { 'allowlist' => 'all' }
      settings.update!(user_opt_in_features: features)
    end

    def disable_opt_in
      features = settings.user_opt_in_features.deep_dup || {}
      features.delete(feature_key)
      settings.update!(user_opt_in_features: features)

      feature = Flipper[feature_key.to_sym]
      feature.actors_value.each do |flipper_actor_id|
        feature.disable_actor(Flipper::Actor.new(flipper_actor_id))
      end
    end

    def settings
      @settings ||= Irida::CurrentSettings.current_application_settings
    end

    def restore_after_audit_failure!
      return unless @previous_opt_in_features || @feature_state_before_mutation

      settings.update!(user_opt_in_features: @previous_opt_in_features)
      restore_feature_state!(feature_key, @feature_state_before_mutation)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      log_mutation_failure('Unable to restore feature state after opt-in audit failure', e)
    end
  end
end
