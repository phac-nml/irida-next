# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :members, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_members, on: :members
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_members" on "members";
        SQL
      end
    end
  end
end
