# frozen_string_literal: true

# Migration to add Routes table
class CreateRoutes < ActiveRecord::Migration[7.0]
  def change
    create_table :routes do |t|
      t.string :path
      t.string :name

      t.references :source, polymorphic: true, index: true

      t.timestamps
    end

    add_index :routes, :path, unique: true
    add_index :routes, :name, unique: true
  end
end
