# frozen_string_literal: true

# migration to save manifest to data_export
class AddManifestToDataExport < ActiveRecord::Migration[7.1]
  def change
    add_column :data_exports, :manifest, :jsonb, null: false, default: {}
  end
end
