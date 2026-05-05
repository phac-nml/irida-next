# frozen_string_literal: true

# Migration to add public column to namespace table.
class AddPublicToNamespace < ActiveRecord::Migration[8.1]
  def change
    add_column :namespaces, :public, :boolean, default: false, null: false
  end
end
