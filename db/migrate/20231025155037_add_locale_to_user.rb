# frozen_string_literal: true

# Migration to add locale to users table
class AddLocaleToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :locale, :string, default: 'en'
  end
end
