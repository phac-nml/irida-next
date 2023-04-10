# frozen_string_literal: true

# Migration to add PersonalAccessTokens table
class CreatePersonalAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :personal_access_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :scopes
      t.string :name
      t.boolean :revoked
      t.date :expires_at
      t.string :token_digest
      t.timestamp :last_used_at

      t.timestamps
    end
    add_index :personal_access_tokens, :token_digest, unique: true
  end
end
