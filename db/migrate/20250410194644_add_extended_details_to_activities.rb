# frozen_string_literal: true

# Migration to add extended details table to be used by activities to store large data
class AddExtendedDetailsToActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :extended_details, id: :uuid do |t|
      t.jsonb :details, default: {}, null: false

      t.timestamps
    end

    create_table :activity_extended_details, id: :uuid do |t|
      t.references :activity, type: :uuid, null: false, foreign_key: true, index: true
      t.references :extended_detail, type: :uuid, null: false, foreign_key: true, index: true
      t.string :activity_type, null: false

      t.timestamps
    end

    add_index :activity_extended_details, %i[activity_id extended_detail_id], unique: true
  end
end
