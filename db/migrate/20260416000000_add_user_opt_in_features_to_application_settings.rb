# frozen_string_literal: true

# Moves user opt-in feature configuration from config/user_opt_in_features.yml
# into a jsonb column on application_settings so it can be edited at runtime.
class AddUserOptInFeaturesToApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :application_settings, :user_opt_in_features, :jsonb, default: {}, null: false
  end
end
