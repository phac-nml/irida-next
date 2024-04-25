# frozen_string_literal: true

# Migration to add AutomatedWorkflowExecution table
class CreateAutomatedWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :automated_workflow_executions, id: :uuid do |t|
      t.references :namespace, type: :uuid, null: false, foreign_key: true
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.jsonb :metadata, null: false, default: { workflow_name: '', workflow_version: '' }
      t.jsonb :workflow_params, null: false, default: {}
      t.boolean :email_notification, null: false, default: true
      t.boolean :update_samples, null: false, default: true

      t.timestamps
    end
  end
end
