# frozen_string_literal: true

# Migration to add a new disabled column to the automated workflow executions table
class AddDisabledToAutomatedWorkflowExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :automated_workflow_executions, :disabled, :boolean, default: false, null: false
  end
end
