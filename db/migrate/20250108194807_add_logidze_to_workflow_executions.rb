# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToWorkflowExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :workflow_executions, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_workflow_executions, on: :workflow_executions

        execute <<~SQL.squish
          UPDATE "workflow_executions" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"cleaned","http_error_code","metadata","workflow_params","workflow_type","workflow_type_version","workflow_engine","workflow_engine_version","workflow_engine_parameters","workflow_url","namespace_id","tags","blob_run_directory","id","submitter_id","email_notification","update_samples"}');
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_workflow_executions" on "workflow_executions";
        SQL
      end
    end
  end
end

