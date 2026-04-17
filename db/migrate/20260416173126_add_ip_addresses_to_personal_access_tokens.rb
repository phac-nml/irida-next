# frozen_string_literal: true

# Migration to add ip_addresses column to personal_access_tokens table
class AddIpAddressesToPersonalAccessTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_access_tokens, :ip_addresses, :inet, array: true, default: []
  end
end
