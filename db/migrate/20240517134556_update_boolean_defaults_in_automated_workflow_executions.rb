class UpdateBooleanDefaultsInAutomatedWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    change_column_default :automated_workflow_executions, :email_notification, from: true, to: false
    change_column_default :automated_workflow_executions, :update_samples, from: true, to: false
  end
end
