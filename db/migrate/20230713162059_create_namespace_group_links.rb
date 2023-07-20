# frozen_string_literal: true

# migration to add table to store shared group to namespace links
class CreateNamespaceGroupLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :namespace_group_links do |t|
      t.bigint :group_id, null: false
      t.bigint :namespace_id, null: false
      t.date :expires_at
      t.integer :group_access_level, null: false
      t.string :namespace_type

      t.timestamps
    end
    add_index :namespace_group_links, %i[group_id namespace_id],
              unique: true,
              name: 'index_group_link_group_with_namespace'
  end
end
