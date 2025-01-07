# frozen_string_literal: true

# Migration to add MetadataTemplates table
class CreateMetadataTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :metadata_templates, id: :uuid do |t|
      t.references :namespace, type: :uuid, null: false, foreign_key: true
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :description
      t.jsonb :fields, null: false, default: []
      t.timestamps
    end
  end
end
