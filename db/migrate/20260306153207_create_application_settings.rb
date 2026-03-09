# frozen_string_literal: true

# This migration creates the application_settings table, which will be used to store settings for the application.
# The settings include:
# - signup_enabled: A boolean that indicates whether user signup is enabled. Default true.
# - password_authentication_enabled: A boolean that indicates whether password authentication is enabled. Default true.
#
# This migration also adds timestamps to the application_settings table to track when settings are created and updated.
class CreateApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :application_settings do |t|
      t.boolean :signup_enabled, default: true, null: false
      t.boolean :password_authentication_enabled, default: true, null: false

      t.timestamps
    end
  end
end
