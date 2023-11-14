# frozen_string_literal: true

# Migration to add SamplesWorkflowExecution table
class SamplesWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    create_table :samples_workflow_executions do |t|
      t.jsonb :samplesheet_params
      t.references :sample
      t.references :workflow_execution

      t.timestamps
    end
  end
end
