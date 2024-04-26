class AddNamespaceRefToWorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    add_reference :workflow_executions, :namespace, type: :uuid, foreign_key: true
  end
end
