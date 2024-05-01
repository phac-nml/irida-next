# frozen_string_literal: true

# migration to add name to automated workflow execution
class AddNameToAutomatedWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :automated_workflow_executions, :name, :string
  end
end
