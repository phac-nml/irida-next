# frozen_string_literal: true

# Migration to add last_used_ips column to personal_access_tokens table
class AddLastUsedIpsToPersonalAccessTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_access_tokens, :last_used_ips, :inet, array: true, default: []
  end
end
