# frozen_string_literal: true

# This migration adds the maximum allowed source size for data exports in gigabytes.
class AddMaxDataExportSizeToApplicationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :application_settings, :max_data_export_size_gigabytes, :integer, default: 30, null: false
  end
end
