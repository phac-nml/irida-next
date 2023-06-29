# frozen_string_literal: true

# migration to add deleted_at column to members
class AddDeletedAtToMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :members, :deleted_at, :datetime
    add_index :members, :deleted_at
  end
end
