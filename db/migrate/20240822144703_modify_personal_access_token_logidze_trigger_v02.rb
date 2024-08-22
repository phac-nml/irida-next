# frozen_string_literal: true

# Migration to modify personal access token logidze trigger
class ModifyPersonalAccessTokenLogidzeTriggerV02 < ActiveRecord::Migration[7.2]
  def up
    update_trigger :logidze_on_personal_access_tokens, on: :personal_access_tokens, version: 2

    execute <<-SQL.squish
      UPDATE "personal_access_tokens" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at", "last_used_at"}');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
