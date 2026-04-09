# frozen_string_literal: true

# migration to change expires_at type in personal_access_tokens from date to datetime
class ChangeExpiresAtTypeInPersonalAccessTokens < ActiveRecord::Migration[8.1]
  def up
    change_column :personal_access_tokens, :expires_at, :datetime, null: true
  end

  def down
    change_column :personal_access_tokens, :expires_at, :date, null: true
  end
end
