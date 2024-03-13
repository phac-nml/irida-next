# frozen_string_literal: true

# migration to add blob_run_directory column to WorkflowExecution
class AddBlobRunDirToWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :blob_run_directory, :string
  end
end
