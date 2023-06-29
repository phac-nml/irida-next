# frozen_string_literal: true

# migration to add deleted_at column to personal_access_tokens
class AddDeletedAtToPersonalAccessTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :personal_access_tokens, :deleted_at, :datetime
    add_index :personal_access_tokens, :deleted_at
  end
end
