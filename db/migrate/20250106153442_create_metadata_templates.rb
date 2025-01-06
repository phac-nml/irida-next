# frozen_string_literal: true

# Migration to add MetadataTemplates table
class CreateMetadataTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :metadata_templates do |t|
      t.string :name
      t.string :description
      t.jsonb :fields
      t.references :namespace, foreign_key: true, index: true
      t.timestamps
    end
  end
end
