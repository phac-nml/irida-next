# frozen_string_literal: true

# Updates the `pipeline_id` to match the entry in the pipelines config
class AddPipelineIdToWorkflowExecutionMetadata < ActiveRecord::Migration[8.0]
  def change # rubocop:disable Metrics/AbcSize
    pipeline_name_to_id = Irida::Pipelines.instance.pipelines.to_h do |_pipeline_id, pipeline_config|
      [pipeline_config.name, pipeline_config.pipeline_id]
    end

    workflow_executions = WorkflowExecution.all
    workflow_executions.each do |workflow_execution|
      workflow_execution.metadata['pipeline_id'] = pipeline_name_to_id[workflow_execution.metadata['workflow_name']]
      workflow_execution.save
    end

    automated_executions = AutomatedWorkflowExecution.all
    automated_executions.each do |automated_execution|
      automated_execution.metadata['pipeline_id'] = pipeline_name_to_id[automated_execution.metadata['workflow_name']]
      automated_execution.save
    end
  end
end
