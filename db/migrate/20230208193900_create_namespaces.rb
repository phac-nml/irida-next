# frozen_string_literal: true

# Migration to add Namespaces table
class CreateNamespaces < ActiveRecord::Migration[7.0]
  def change
    create_table :namespaces do |t|
      t.string :name
      t.string :path
      t.references :owner, index: true
      t.string :type
      t.string :description
      t.references :parent, foreign_key: { to_table: :namespaces }, index: true

      t.timestamps
    end
  end
end
