# frozen_string_literal: true

module SystemFeatureFlags
  # Changes the global Flipper boolean gate for an admin-manageable feature.
  class UpdateGlobalState < BaseFeatureFlagService
    TARGET_STATES = %w[enabled disabled].freeze

    def initialize(feature_key:, target_state:, user:)
      super()
      @feature_key = feature_key.to_s
      @target_state = target_state.to_s
      @user = user
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return failure(:unauthorized, feature_key:) unless system_user?(user)
      return failure(:invalid_feature, feature_key:) unless Irida::SystemFeatureFlagsCatalog.admin_manageable?(
        feature_key
      )
      return failure(:invalid_target_state, feature_key:) unless TARGET_STATES.include?(target_state)

      # Pre-lock optimization: skip lock if already in target state.
      # May be stale under concurrency; the in-lock re-check guarantees correctness.
      return no_op_result if Irida::SystemFeatureFlagsCatalog.global_state(feature_key) == target_state

      applied = with_feature_lock(feature_key:) do
        next if Irida::SystemFeatureFlagsCatalog.global_state(feature_key) == target_state

        @feature_state_before_mutation = snapshot_feature_state(feature_key)
        apply_target_state!
        true
      end

      return no_op_result if applied.nil?

      success(feature_key:)
    rescue ActiveRecord::ActiveRecordError, Flipper::Error => e
      # Defensive: transaction rollback restores DB state, but this ensures
      # Flipper's in-memory cache is consistent with the database.
      restore_feature_state!(feature_key, @feature_state_before_mutation) unless @feature_state_before_mutation.nil?
      log_mutation_failure('Unable to change global experimental feature state', e)
      failure(:mutation_failed, feature_key:)
    end

    private

    attr_reader :feature_key, :target_state, :user

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
