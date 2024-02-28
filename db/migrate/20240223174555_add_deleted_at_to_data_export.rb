# frozen_string_literal: true

# migration to add deleted_at column to DataExport
class AddDeletedAtToDataExport < ActiveRecord::Migration[7.1]
  def change
    add_column :data_exports, :deleted_at, :datetime
    add_index :data_exports, :deleted_at
  end
end
