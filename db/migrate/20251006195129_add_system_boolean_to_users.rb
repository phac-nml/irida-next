# frozen_string_literal: true

# adds system boolean column to users table
class AddSystemBooleanToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :system, :boolean, default: false, null: false
  end
end
