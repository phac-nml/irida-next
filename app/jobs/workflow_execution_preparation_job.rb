# frozen_string_literal: true

# Calls the workflow execution preparation service and then queues up the next workflow to execute
class WorkflowExecutionPreparationJob < ApplicationJob
  queue_as :default

  def perform
    workflow_executions = WorkflowExecution.where(state: 'new')

    workflow_executions.each do |workflow_execution|
      WorkflowExecutions::PreparationService.new(workflow_execution).execute
    end
  end
end
