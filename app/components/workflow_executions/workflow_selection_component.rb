# frozen_string_literal: true

module WorkflowExecutions
  # Component for rendering and organizing the workflow selection buttons
  class WorkflowSelectionComponent < Component
    def initialize(workflows:, namespace_id:, sample_count:)
      @workflows = workflows
      @namespace_id = namespace_id
      @sample_count = sample_count.to_i
      @organized_workflows = { available: [], unavailable: [] }
      organize_workflows
    end

    private

    def organize_workflows # rubocop:disable Metrics/MethodLength
      @workflows.each do |_, workflow| # rubocop:disable Style/HashEachMethods
        min_samples_configured = workflow.min_samples_limit_configured?
        max_samples_configured = workflow.max_samples_limit_configured?
        message = ''

        if min_samples_configured && @sample_count < minimum_samples(min_samples_configured, workflow)
          message = I18n.t('shared.workflow_executions.sample_limits.min_samples_required',
                           min_samples: workflow.minimum_samples)
        end

        if max_samples_configured && @sample_count > workflow.maximum_samples.to_i
          message = I18n.t('shared.workflow_executions.sample_limits.max_samples_exceeded',
                           max_samples: workflow.maximum_samples)
        end

        if message.blank?
          @organized_workflows[:available] << workflow
        else
          @organized_workflows[:unavailable] << { workflow:, message: }
        end
      end
    end

    def minimum_samples(min_samples_configured, workflow)
      if min_samples_configured
        workflow.minimum_samples.to_i
      else
        0
      end
    end
  end
end
