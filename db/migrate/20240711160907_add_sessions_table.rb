# frozen_string_literal: true

# migration to add sessions table for storing session data
class AddSessionsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.jsonb :data
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :updated_at
  end
end
