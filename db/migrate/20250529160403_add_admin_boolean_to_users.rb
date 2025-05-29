# frozen_string_literal: true

# adds admin boolean column to users table
class AddAdminBooleanToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin, :boolean, default: false, null: false
  end
end
