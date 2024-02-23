# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToDataExports < ActiveRecord::Migration[7.1]
  def change
    add_column :data_exports, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_data_exports, on: :data_exports
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_data_exports" on "data_exports";
        SQL
      end
    end
  end
end
