# frozen_string_literal: true

# Migration to add Projects table
class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.references :creator, foreign_key: { to_table: :users }, index: true
      t.references :namespace, foreign_key: true, index: true

      t.timestamps
    end
  end
end
