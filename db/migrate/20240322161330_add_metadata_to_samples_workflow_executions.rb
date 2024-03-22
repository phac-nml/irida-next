# frozen_string_literal: true

# Migration to add metadata column to samples_workflow_executions table
class AddMetadataToSamplesWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :samples_workflow_executions, :metadata, :jsonb, null: false, default: {}
  end
end
