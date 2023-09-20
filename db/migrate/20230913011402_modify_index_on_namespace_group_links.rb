# frozen_string_literal: true

# migration to update the unique index to only check for records where deleted at is null
class ModifyIndexOnNamespaceGroupLinks < ActiveRecord::Migration[7.0]
  def change
    remove_index :namespace_group_links, %i[group_id namespace_id],
                 unique: true,
                 name: 'index_group_link_group_with_namespace'

    add_index :namespace_group_links, %i[group_id namespace_id],
              unique: true,
              name: 'index_group_link_group_with_namespace',
              where: 'deleted_at is null'
  end
end
