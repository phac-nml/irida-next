# frozen_string_literal: true

# migration to add table to store shared group to group links
class CreateGroupGroupLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :group_group_links do |t|
      t.bigint :shared_group_id, null: false
      t.bigint :shared_with_group_id,  null: false
      t.date :expires_at
      t.integer :group_access_level, null: false

      t.timestamps
    end
    add_index :group_group_links, %i[shared_group_id shared_with_group_id],
              unique: true,
              name: 'index_group_link_shared_group_id_with_shared_with_group_id'
  end
end
