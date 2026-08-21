# frozen_string_literal: true

# Add archived_at column to namespace table
class AddArchivedAtToNamespaces < ActiveRecord::Migration[8.1]
  def change
    add_column :namespaces, :archived_at, :datetime
    add_index :namespaces, :archived_at
  end
end
