# frozen_string_literal: true

# This migration adds a personal access token clean up inactive tokens setting to the application_settings table.
class AddCleanupInactiveTokensAfterDaysSetting < ActiveRecord::Migration[8.1]
  def change
    add_column :application_settings, :cleanup_inactive_access_tokens_after_days, :integer, default: 30, null: false
  end
end
