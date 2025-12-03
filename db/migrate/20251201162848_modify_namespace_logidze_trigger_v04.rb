# frozen_string_literal: true

# Migration to modify namespace logidze trigger
class ModifyNamespaceLogidzeTriggerV04 < ActiveRecord::Migration[8.0]
  def up
    update_trigger :logidze_on_namespaces, on: :namespaces, version: 4

    execute <<-SQL.squish
      UPDATE "namespaces" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"metadata_summary", "updated_at", "attachments_updated_at", "samples_count"}');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
