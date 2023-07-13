# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToNamespaceGroupLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :namespace_group_links, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_namespace_group_links, on: :namespace_group_links
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_namespace_group_links" on "namespace_group_links";
        SQL
      end
    end
  end
end
