# frozen_string_literal: true

# Migration to add Attachments table
class CreateAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :attachments do |t|
      t.jsonb :metadata, null: false, default: {}
      t.datetime :deleted_at
      t.references :attachable, polymorphic: true, null: false, index: true

      t.timestamps
    end

    add_index :attachments, :metadata, using: :gin
  end
end
