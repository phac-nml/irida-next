# frozen_string_literal: true

# Migration to add DataExport table
class CreateDataExports < ActiveRecord::Migration[7.1]
  def change
    create_table :data_exports, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :name
      t.string :export_type, null: false
      t.string :status, null: false
      t.jsonb :export_parameters, null: false, default: {}
      t.datetime :expires_at
      t.boolean :email_notification, null: false, default: false

      t.timestamps
    end
  end
end
