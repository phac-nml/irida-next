# frozen_string_literal: true

# This migration adds personal access token settings to the application_settings table.
# The settings include:
# - require_personal_access_token_expiry: A boolean that indicates whether personal access token expiry is required.
# Default false.
# - max_personal_access_token_lifetime_in_days: An integer that specifies the maximum lifetime of a personal access
# token in days. Default 365.
class AddPersonalAccessTokenSettingsToApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :application_settings, :require_personal_access_token_expiry, :boolean, default: false, null: false
    add_column :application_settings, :max_personal_access_token_lifetime_in_days, :integer, default: 365, null: false
  end
end
