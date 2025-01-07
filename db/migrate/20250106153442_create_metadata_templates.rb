# frozen_string_literal: true

# Migration to add MetadataTemplates table
class CreateMetadataTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :metadata_templates, id: :uuid do |t|
      t.references :namespace, type: :uuid, foreign_key: true, index: true
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :name
      t.string :description
      t.jsonb :fields, null: false, default: []
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :metadata_templates, %i[namespace_id name],
              unique: true,
              where: '(deleted_at IS NULL)',
              name: 'index_template_name_with_namespace'
  end
end
