# frozen_string_literal: true

# migration to add members table
class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members do |t|
      t.integer :user_id
      t.integer :namespace_id
      t.string :role

      t.timestamps
    end
    add_index :members, %i[user_id namespace_id], unique: true
  end
end
