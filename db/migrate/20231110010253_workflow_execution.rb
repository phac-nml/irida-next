# frozen_string_literal: true

# Migration to add WorkflowExecution table
class WorkflowExecution < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_executions do |t|
      t.jsonb :metadata
      t.jsonb :workflow_params
      t.string :workflow_type
      t.string :workflow_type_version
      t.string :tags, array: true
      t.string :workflow_engine
      t.string :workflow_engine_version
      t.string :workflow_engine_parameters
      t.string :workflow_url
      t.string :run_id
      t.references :submitter
      # states to be defined in a later migration
      # t.enum :state, enum_type: :workflow_execution_state, default: 'tbd'

      t.timestamps
    end
    # states to be defined in a later migration
    # create_enum :workflow_execution_state, ['tbd']
  end
end
