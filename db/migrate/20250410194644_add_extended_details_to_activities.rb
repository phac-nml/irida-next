# frozen_string_literal: true

# Migration to add extended details table to be used by activities to store large data
class AddExtendedDetailsToActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :extended_details, id: :uuid do |t|
      t.jsonb :details, default: {}, null: false

      t.timestamps
    end

    change_table :activities do |t|
      t.uuid :extended_details_id
    end
    # add_index :activities, :extended_details_id, unique: true
  end
end
