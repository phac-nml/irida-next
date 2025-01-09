# frozen_string_literal: true

# Migration to add Logidze to MetadataTemplates table
class AddLogidzeToMetadataTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :metadata_templates, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_metadata_templates, on: :metadata_templates
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_metadata_template" on "metadata_templates";
        SQL
      end
    end
  end
end
