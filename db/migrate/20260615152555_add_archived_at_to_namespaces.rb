# frozen_string_literal: true

# Add archived_at column to namespace table
class AddArchivedAtToNamespaces < ActiveRecord::Migration[8.1]
  def change
    add_column :namespaces, :archived_at, :datetime
  end
end
