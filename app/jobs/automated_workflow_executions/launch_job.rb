# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Queues the automated workflow execution launch job
  class LaunchJob < ApplicationJob
    queue_as :default

    def perform(sample, pe_attachment_pair)
      sample.project.namespace.automated_workflow_executions.each do |awe|
        AutomatedWorkflowExecutions::LaunchService.new(awe, sample, pe_attachment_pair,
                                                       sample.project.namespace.automation_bot).execute
      end
    end
  end
end
