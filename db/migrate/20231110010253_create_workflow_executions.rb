# frozen_string_literal: true

# Migration to add WorkflowExecution table
class CreateWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength
    create_table :workflow_executions do |t|
      t.jsonb :metadata, null: false, default: { workflow_name: '', workflow_version: '' }
      t.jsonb :workflow_params, null: false, default: {}
      t.string :workflow_type
      t.string :workflow_type_version
      t.string :tags, array: true
      t.string :workflow_engine
      t.string :workflow_engine_version
      t.jsonb :workflow_engine_parameters, null: false, default: {}
      t.string :workflow_url
      t.string :run_id
      t.references :submitter
      t.string :state

      t.datetime :deleted_at

      t.timestamps
    end
  end
end
