# frozen_string_literal: true

# Migration to add Namespaces table
class CreateNamespaces < ActiveRecord::Migration[7.0]
  def change
    create_table :namespaces do |t|
      t.string :name
      t.string :path
      t.integer :owner_id
      t.string :type
      t.string :description
      t.integer :parent_id

      t.timestamps
    end
  end
end
