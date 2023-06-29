# frozen_string_literal: true

# migration to update the unique index to only check for records where deleted at is null
class ModifyIndexOnRoutes < ActiveRecord::Migration[7.0]
  def change
    remove_index :routes, :path, unique: true
    remove_index :routes, :name, unique: true

    add_index :routes, :path, unique: true, where: 'deleted_at is null'
    add_index :routes, :name, unique: true, where: 'deleted_at is null'
  end
end
