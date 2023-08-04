# frozen_string_literal: true

# migration to add deleted_at column to namespace_group_links
class AddDeletedAtToNamespaceGroupLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :namespace_group_links, :deleted_at, :datetime
    add_index :namespace_group_links, :deleted_at
  end
end
