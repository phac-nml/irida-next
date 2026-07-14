# frozen_string_literal: true

module SystemFeatureFlags
  # Shared orchestration for feature-flag mutation services.
  class BaseFeatureFlagService
    # Small return contract for UI-independent feature flag mutation services.
    Result = Data.define(:status, :entry, :error) do
      def success?
        status == :success
      end

      def no_op?
        status == :no_op
      end

      def failure?
        status == :failure
      end
    end

    # Internal sentinel used to abort a mutation inside a transaction with a typed error.
    class AbortMutation < StandardError
      attr_reader :error

      def initialize(error)
        @error = error
        super(error.to_s)
      end
    end

    private

    def system_user?(user)
      user&.system?
    end

    def success(feature_key:, entry: nil)
      Result.new(status: :success, entry: entry || Irida::SystemFeatureFlagsCatalog.fetch(feature_key),
                 error: nil)
    end

    def no_op(feature_key:, entry: nil)
      Result.new(status: :no_op, entry: entry || Irida::SystemFeatureFlagsCatalog.fetch(feature_key),
                 error: nil)
    end

    def failure(error, feature_key:, entry: nil)
      Result.new(status: :failure, entry: entry || Irida::SystemFeatureFlagsCatalog.fetch(feature_key),
                 error: error)
    end

    def with_feature_lock(feature_key:, settings: nil)
      ApplicationRecord.transaction do
        settings&.lock!
        lock_flipper_records!(feature_key)
        yield
      end
    end

    def abort_mutation!(error)
      raise AbortMutation, error
    end

    def log_mutation_failure(message, exception)
      Rails.logger.error("#{message}: #{exception.message}")
    end

    def lock_flipper_records!(feature_key)
      Flipper::Adapters::ActiveRecord::Feature.lock.find_or_create_by!(key: feature_key)
    rescue ActiveRecord::RecordNotUnique
      # Concurrent insert race: another transaction created the row first.
      retry
    ensure
      Flipper::Adapters::ActiveRecord::Gate.lock.where(feature_key: feature_key).load
    end

    def snapshot_feature_state(feature_key)
      feature = Flipper[feature_key.to_sym]

      {
        boolean: feature.boolean_value,
        actors: feature.actors_value.to_a,
        groups: feature.groups_value.to_a,
        percentage_of_actors: feature.percentage_of_actors_value.to_i,
        percentage_of_time: feature.percentage_of_time_value.to_i,
        expression: feature.expression_value
      }
    end

    # Defensive restore: transaction rollback already reverts DB state, but this
    # ensures Flipper's in-memory feature cache is consistent with the database.
    def restore_feature_state!(feature_key, state) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      feature = Flipper[feature_key.to_sym]
      feature.clear
      return if state.nil?

      feature.enable if state[:boolean]
      state[:actors].each { |flipper_actor_id| feature.enable_actor(Flipper::Actor.new(flipper_actor_id)) }
      state[:groups].each { |group| feature.enable_group(group) }
      feature.enable_percentage_of_actors(state[:percentage_of_actors]) if state[:percentage_of_actors].positive?
      feature.enable_percentage_of_time(state[:percentage_of_time]) if state[:percentage_of_time].positive?

      expression = state[:expression]
      return if expression.blank?

      expression_payload = expression.respond_to?(:value) ? expression.value : expression
      feature.enable_expression(expression_payload)
    end
  end
end
