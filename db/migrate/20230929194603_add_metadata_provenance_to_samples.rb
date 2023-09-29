# frozen_string_literal: true

# Migration to add metadata_provenance column to samples table
class AddMetadataProvenanceToSamples < ActiveRecord::Migration[7.0]
  def change
    add_column :samples, :metadata_provenance, :jsonb, null: false, default: {}
    add_index :samples, :metadata_provenance, using: :gin
  end
end
