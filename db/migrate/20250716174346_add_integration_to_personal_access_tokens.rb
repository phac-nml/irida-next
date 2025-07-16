# frozen_string_literal: true

# adds boolean :integration field to PersonalAccessTokens model
class AddIntegrationToPersonalAccessTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :personal_access_tokens, :integration, :boolean, default: false, null: false
    add_column :personal_access_tokens, :integration_host, :string, default: nil
  end
end
