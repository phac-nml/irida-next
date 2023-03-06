# frozen_string_literal: true

# Migration to add Projects table
class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.integer :creator_id
      t.integer :namespace_id

      t.timestamps
    end
  end
end
