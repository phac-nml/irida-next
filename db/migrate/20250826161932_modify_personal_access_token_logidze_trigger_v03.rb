# frozen_string_literal: true

# Migration to modify personal access token logidze trigger
class ModifyPersonalAccessTokenLogidzeTriggerV03 < ActiveRecord::Migration[8.0]
  def up
    update_trigger :logidze_on_personal_access_tokens, on: :personal_access_tokens, version: 3

    execute <<-SQL.squish
      UPDATE "personal_access_tokens" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"last_used_at", "updated_at"}');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
