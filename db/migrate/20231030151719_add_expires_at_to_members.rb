# frozen_string_literal: true

# migration to add expires_at column to members
class AddExpiresAtToMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :members, :expires_at, :date
    add_index :members, :expires_at
  end
end
