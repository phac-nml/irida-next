# frozen_string_literal: true

# migration to add missing unique indexes
class AddMissingUniqueIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :members, %i[user_id namespace_id],
              unique: true,
              name: 'index_member_user_with_namespace'

    add_index :namespace_group_links, %i[group_id namespace_id],
              unique: true,
              name: 'index_namespace_group_link_user_with_namespace'

    add_index :samples, %i[name project_id],
              unique: true,
              name: 'index_sample_name_with_project'
  end
end
