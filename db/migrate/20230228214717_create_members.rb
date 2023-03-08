# frozen_string_literal: true

# migration to add members table
class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members do |t|
      t.integer :user_id
      t.integer :namespace_id
      t.integer :created_by_id
      t.string :type
      t.integer :access_level

      t.timestamps
    end
    add_index :members, %i[user_id namespace_id], unique: true
  end
end
