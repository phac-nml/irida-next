# frozen_string_literal: true

# Migration to add user_type column to users table
class AddUserTypeToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :user_type, :integer, default: 0

    execute <<-SQL.squish
        UPDATE users SET user_type=0
    SQL

    User.reset_log_data
    User.create_logidze_snapshot(timestamp: :created_at, except: %w[created_at updated_at])
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
