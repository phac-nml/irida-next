# frozen_string_literal: true

module SystemFeatureFlags
  # Changes the global Flipper boolean gate for an admin-manageable feature and audits the result.
  class ChangeGlobalState < MutationService
    TARGET_STATES = %w[enabled disabled].freeze
    ACTION_BY_TARGET_STATE = {
      'enabled' => 'enable_global',
      'disabled' => 'disable_global'
    }.freeze

    class << self
      def call(feature_key:, target_state:, actor:)
        new(feature_key:, target_state:, actor:).call
      end
    end

    def initialize(feature_key:, target_state:, actor:)
      super()
      @feature_key = feature_key.to_s
      @target_state = target_state.to_s
      @actor = actor
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return failure(:unauthorized, feature_key:) unless system_actor?(actor)
      return failure(:invalid_feature, feature_key:) unless Catalog.admin_manageable?(feature_key)
      return failure(:invalid_target_state, feature_key:) unless TARGET_STATES.include?(target_state)

      # Pre-lock optimization: skip lock if already in target state.
      # May be stale under concurrency; the in-lock re-check guarantees correctness.
      return no_op_result if Catalog.global_state(feature_key) == target_state

      change = with_feature_lock(feature_key:) do
        old_global_state = Catalog.global_state(feature_key)
        old_opt_in_state = Catalog.opt_in_state(feature_key)
        next if old_global_state == target_state

        @feature_state_before_mutation = snapshot_feature_state(feature_key)
        cleared_gate_summary = Catalog.conditional_gate_summary(feature_key)
        apply_target_state!

        create_change!(
          actor:,
          feature_key:,
          action: ACTION_BY_TARGET_STATE.fetch(target_state),
          old_global_state:,
          new_global_state: Catalog.global_state(feature_key),
          old_opt_in_state:,
          new_opt_in_state: Catalog.opt_in_state(feature_key),
          cleared_gate_summary:
        )
      end

      return no_op_result if change.nil?

      success(change:, feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      # Defensive: transaction rollback restores DB state, but this ensures
      # Flipper's in-memory cache is consistent with the database.
      restore_feature_state!(feature_key, @feature_state_before_mutation) unless @feature_state_before_mutation.nil?
      log_mutation_failure('Unable to change global experimental feature state', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :target_state, :actor

    def no_op_result
      no_op(feature_key:)
    end

    def apply_target_state!
      if target_state == 'enabled'
        Flipper.enable(feature_key.to_sym)
      else
        Flipper.disable(feature_key.to_sym)
      end
    end
  end
end
