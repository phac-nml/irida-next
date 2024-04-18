# frozen_string_literal: true

# Migration to add a new column update_samples to the workflow_executions table
class AddUpdateSamplesToWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :update_samples, :boolean, default: false, null: false
  end
end
