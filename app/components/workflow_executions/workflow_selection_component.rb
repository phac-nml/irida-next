# frozen_string_literal: true

module WorkflowExecutions
  # Component for rendering and organizing the workflow selection
  class WorkflowSelectionComponent < Component
    def initialize(workflows:, namespace_id:, sample_count:)
      @workflows = workflows
      @namespace_id = namespace_id
      @sample_count = sample_count.to_i
      @organized_workflows = organize_workflows
    end

    private

    def organize_workflows
      @workflows.each_with_object(available: [], unavailable: []) do |(_, workflow), organized|
        message = sample_limit_message(workflow)

        if message.blank?
          organized[:available] << workflow
        else
          organized[:unavailable] << { workflow:, message: }
        end
      end
    end

    def sample_limit_message(workflow)
      min_samples_configured = workflow.min_samples_limit_configured?
      max_samples_configured = workflow.max_samples_limit_configured?

      if min_samples_configured && @sample_count < minimum_samples(min_samples_configured, workflow)
        I18n.t('shared.workflow_executions.sample_limits.min_samples_required',
               min_samples: workflow.minimum_samples)

      elsif max_samples_configured && @sample_count > workflow.maximum_samples.to_i
        I18n.t('shared.workflow_executions.sample_limits.max_samples_exceeded',
               max_samples: workflow.maximum_samples)
      else
        ''
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
