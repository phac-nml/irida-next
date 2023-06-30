# frozen_string_literal: true

# migration to add deleted_at column to group_group_links
class AddDeletedAtToGroupGroupLink < ActiveRecord::Migration[7.0]
  def change
    add_column :group_group_links, :deleted_at, :datetime
    add_index :group_group_links, :deleted_at
  end
end
