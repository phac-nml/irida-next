class AddLogidzeToWorkflowExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :workflow_executions, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_workflow_executions, on: :workflow_executions
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_workflow_executions" on "workflow_executions";
        SQL
      end
    end
  end
end
