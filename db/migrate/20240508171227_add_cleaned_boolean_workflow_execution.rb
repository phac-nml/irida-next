# frozen_string_literal: true

# Migration to add cleaned column to workflow_executions table
class AddCleanedBooleanWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :cleaned, :boolean, default: false, null: false
  end
end
