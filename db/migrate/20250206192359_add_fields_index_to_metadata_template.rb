# frozen_string_literal: true

# Migration to add fields uniqueness index to metadata templates
class AddFieldsIndexToMetadataTemplate < ActiveRecord::Migration[7.2]
  def change
    add_index :metadata_templates, %i[fields namespace_id],
              unique: true,
              where: '(deleted_at IS NULL)',
              name: 'index_template_fields_with_namespace'
  end
end
