# frozen_string_literal: true

# migration to add deleted_at column to namespaces
class AddDeletedAtToNamespaces < ActiveRecord::Migration[7.0]
  def change
    add_column :namespaces, :deleted_at, :datetime
    add_index :namespaces, :deleted_at
  end
end
