# frozen_string_literal: true

# migration to update the unique index to only check for records where deleted at is null
class ModifyIndexOnMembers < ActiveRecord::Migration[7.0]
  def change
    remove_index :members, %i[user_id namespace_id], unique: true
    add_index :members, %i[user_id namespace_id], unique: true, where: 'deleted_at is null'
  end
end
