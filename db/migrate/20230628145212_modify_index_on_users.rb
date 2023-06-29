# frozen_string_literal: true

# migration to update the unique index to only check for records where deleted at is null
class ModifyIndexOnUsers < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, :email,                unique: true
    remove_index :users, :reset_password_token, unique: true

    add_index :users, :email,                unique: true, where: 'deleted_at is null'
    add_index :users, :reset_password_token, unique: true, where: 'deleted_at is null'
  end
end
