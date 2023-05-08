# frozen_string_literal: true

# Add provider and uid to User for omniauth
class AddOmniauthToUsers < ActiveRecord::Migration[7.0]
  def change_table :users
    add_column :provider, :string
    add_column :uid, :string
  end
end
