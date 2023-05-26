# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToPersonalAccessTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :personal_access_tokens, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_personal_access_tokens, on: :personal_access_tokens
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_personal_access_tokens" on "personal_access_tokens";
        SQL
      end
    end
  end
end
