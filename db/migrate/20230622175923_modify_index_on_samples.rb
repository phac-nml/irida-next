# frozen_string_literal: true

# migration to update the unique index to only check for records where deleted at is null
class ModifyIndexOnSamples < ActiveRecord::Migration[7.0]
  def change
    remove_index :samples, %i[name project_id], unique: true
    add_index :samples, %i[name project_id], unique: true, where: 'deleted_at is null'
  end
end
