# frozen_string_literal: true

# Migration to add error_code column to workflow_executions table
class AddErrorCodeToWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :error_code, :integer
  end
end
