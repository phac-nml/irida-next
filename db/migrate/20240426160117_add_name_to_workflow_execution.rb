# frozen_string_literal: true

# migration to add name to workflow execution
class AddNameToWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :name, :string
  end
end
