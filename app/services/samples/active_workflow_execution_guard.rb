# frozen_string_literal: true

module Samples
  # Shared guard for sample operations that must be blocked while a sample
  # is participating in active workflow executions.
  module ActiveWorkflowExecutionGuard
    ACTIVE_WORKFLOW_EXECUTION_STATES = %w[initial prepared submitted running].freeze

    private

    # Validate that samples do not have active workflow executions.
    #
    # Prevents actions on samples that are currently being used in a workflow execution.
    # Active workflow states are: initial, prepared, submitted, running.
    #
    # @param sample_ids [Array<Integer>] IDs of samples to check
    # @param action_type [String] action i18n namespace (e.g., 'transfer', 'destroy')
    # @param error_class [Class] exception class to raise on validation failure
    # @raise [StandardError] if any samples have active workflow executions
    def validate_no_active_workflow_executions_for_action(sample_ids, action_type:, error_class:)
      active_workflow_sample_puids = active_workflow_execution_sample_puids(sample_ids)

      return if active_workflow_sample_puids.empty?

      raise error_class,
            I18n.t("services.samples.#{action_type}.active_workflow_executions",
                   sample_puids: active_workflow_sample_puids.join(', '))
    end

    def active_workflow_execution_sample_puids(sample_ids)
      Sample.where(id: sample_ids)
            .joins(samples_workflow_executions: :workflow_execution)
            .where(workflow_executions: { state: ACTIVE_WORKFLOW_EXECUTION_STATES })
            .distinct
            .pluck(:puid)
    end
  end
end
