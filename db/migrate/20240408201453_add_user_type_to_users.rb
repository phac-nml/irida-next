# frozen_string_literal: true

# Migration to add user_type column to users table
class AddUserTypeToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :user_type, :integer, default: 0

    execute <<~SQL.squish
      UPDATE users SET user_type=0;
      UPDATE "users" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
