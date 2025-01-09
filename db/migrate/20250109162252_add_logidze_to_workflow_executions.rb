class AddLogidzeToWorkflowExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :workflow_executions, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_workflow_executions, on: :workflow_executions

        execute <<-SQL.squish
          UPDATE "workflow_executions" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"run_id","name","state","deleted_at"}', true);
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_workflow_executions" on "workflow_executions";
        SQL
      end
    end
  end
end
