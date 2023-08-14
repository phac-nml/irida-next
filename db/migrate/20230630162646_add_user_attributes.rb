# frozen_string_literal: true

# Add more attributes to User which can be fetched from authenticators
class AddUserAttributes < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :first_name
      t.string :last_name
    end
  end
end
