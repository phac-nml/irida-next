# frozen_string_literal: true

# Migration to add a new shared_with_namespace column to the workflow executions table
class AddSharedWithNamespaceToWorkflowExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :workflow_executions, :shared_with_namespace, :boolean, default: false, null: false
  end
end
