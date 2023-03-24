# frozen_string_literal: true

# Migration to add Samples table
class CreateSamples < ActiveRecord::Migration[7.0]
  def change
    create_table :samples do |t|
      t.string :name
      t.text :description
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
    add_index :samples, %i[name project_id], unique: true
  end
end
