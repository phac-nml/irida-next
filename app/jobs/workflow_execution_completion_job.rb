# frozen_string_literal: true

# Queues the workflow execution completion job
class WorkflowExecutionCompletionJob < ApplicationJob
  queue_as :default
  queue_with_priority 10

  def perform(workflow_execution)
    WorkflowExecutions::CompletionService.new(workflow_execution).execute
  end
end
