# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_attachments, on: :attachments
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_attachments" on "attachments";
        SQL
      end
    end
  end
end
