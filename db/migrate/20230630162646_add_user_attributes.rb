# frozen_string_literal: true

# Add more attributes to User which can be fetched from authenticators
class AddUserAttributes < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider_username
      t.string :first_name
      t.string :last_name
      t.string :phone_number
    end
  end
end
