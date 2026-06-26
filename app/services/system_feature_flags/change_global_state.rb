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

    def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return failure(:unauthorized, feature_key:) unless system_actor?(actor)
      return failure(:invalid_feature, feature_key:) unless Catalog.admin_manageable?(feature_key)
      return failure(:invalid_target_state, feature_key:) unless TARGET_STATES.include?(target_state)

      old_global_state = Catalog.global_state(feature_key)
      old_opt_in_state = Catalog.opt_in_state(feature_key)
      return no_op_result(old_global_state, old_opt_in_state) if old_global_state == target_state

      change = with_feature_lock(feature_key:) do
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

      success(change:, feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      restore_feature_state!(feature_key, @feature_state_before_mutation) unless @feature_state_before_mutation.nil?
      log_mutation_failure('Unable to change global experimental feature state', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :target_state, :actor

    def no_op_result(old_global_state, old_opt_in_state)
      entry = Catalog.fetch(feature_key)&.merge(global_state: old_global_state, opt_in_state: old_opt_in_state)
      no_op(feature_key:, entry:)
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
