# frozen_string_literal: true

module WorkflowExecutions
  # Component for rendering selection buttons within launch workflow dialog
  class WorkflowSelectionComponent < Component
    def initialize(workflows:, namespace_id:, sample_count:)
      @workflows = workflows
      @namespace_id = namespace_id
      @sample_count = sample_count

      organize_workflows
      # @workflow = workflow
      # @sample_count = sample_count.to_i
      # @max_samples_configured = max_samples_configured?
      # @min_samples_configured = min_samples_configured?
      # @disabled_message = validate_workflow
      # @disabled = @disabled_message.present?
    end

    private

    def organize_workflows; end

    def min_samples_configured?
      @workflow.min_samples_limit_configured?
    end

    def max_samples_configured?
      @workflow.max_samples_limit_configured?
    end

    def validate_workflow
      return '' unless @max_samples_configured || @min_samples_configured

      if @min_samples_configured && @sample_count < minimum_samples
        return I18n.t('shared.workflow_executions.sample_limits.min_samples_required',
                      min_samples: @workflow.minimum_samples)
      end

      return unless @max_samples_configured && @sample_count > @workflow.maximum_samples.to_i

      I18n.t('shared.workflow_executions.sample_limits.max_samples_exceeded', max_samples: @workflow.maximum_samples)
    end

    def minimum_samples
      if @min_samples_configured
        @workflow.minimum_samples.to_i
      else
        0
      end
    end
  end
end
