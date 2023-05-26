# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToNamespaces < ActiveRecord::Migration[7.0]
  def change
    add_column :namespaces, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_namespaces, on: :namespaces
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_namespaces" on "namespaces";
        SQL
      end
    end
  end
end
