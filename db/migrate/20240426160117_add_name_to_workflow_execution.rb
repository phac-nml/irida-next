class AddNameToWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :name, :string
  end
end
