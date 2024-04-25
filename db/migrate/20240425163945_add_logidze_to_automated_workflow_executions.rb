# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToAutomatedWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :automated_workflow_executions, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_automated_workflow_executions, on: :automated_workflow_executions
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_automated_workflow_executions" on "automated_workflow_executions";
        SQL
      end
    end
  end
end
