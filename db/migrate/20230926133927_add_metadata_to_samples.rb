# frozen_string_literal: true

# Migration to add metadata column to samples table
class AddMetadataToSamples < ActiveRecord::Migration[7.0]
  def change
    add_column :samples, :metadata, :jsonb, null: false, default: {}
    add_index :samples, :metadata, using: :gin
  end
end
