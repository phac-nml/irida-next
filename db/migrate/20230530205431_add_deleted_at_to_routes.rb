# frozen_string_literal: true

# migration to add deleted_at column to routes
class AddDeletedAtToRoutes < ActiveRecord::Migration[7.0]
  def change
    add_column :routes, :deleted_at, :datetime
    add_index :routes, :deleted_at
  end
end
