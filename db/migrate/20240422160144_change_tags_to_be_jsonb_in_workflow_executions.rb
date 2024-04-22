# frozen_string_literal: true

# Migration to change tags to jsonb from string array
class ChangeTagsToBeJsonbInWorkflowExecutions < ActiveRecord::Migration[7.1]
  def up
    remove_column :workflow_executions, :tags
    add_column :workflow_executions, :tags, :jsonb, null: false, default: {}
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
