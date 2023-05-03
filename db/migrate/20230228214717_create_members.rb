# frozen_string_literal: true

# migration to add members table
class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members do |t|
      t.references :user, foreign_key: true, index: true
      t.references :namespace, foreign_key: true, index: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :type
      t.integer :access_level

      t.timestamps
    end
    add_index :members, %i[user_id namespace_id], unique: true
  end
end
