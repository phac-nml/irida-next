# frozen_string_literal: true

class AddPipelineIdToWorkflowExecutionMetadata < ActiveRecord::Migration[8.0]
  def change
    workflow_executions = WorkflowExecution.all

    workflow_executions.each do |workflow_execution|
      workflow_execution.metadata['pipeline_id'] = workflow_execution.metadata['workflow_name']
      workflow_execution.save
    end
  end
end
