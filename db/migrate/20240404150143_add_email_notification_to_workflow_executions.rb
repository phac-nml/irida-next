# frozen_string_literal: true

# Migration to add a new column email_notification to the workflow_executions table
class AddEmailNotificationToWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_executions, :email_notification, :boolean, default: false, null: false
  end
end
