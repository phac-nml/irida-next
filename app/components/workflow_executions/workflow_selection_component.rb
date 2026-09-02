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
        message = workflow.sample_limit_message(@sample_count)

        if message.blank?
          organized[:available] << workflow
        else
          organized[:unavailable] << { workflow:, message: }
        end
      end
    end
  end
end
