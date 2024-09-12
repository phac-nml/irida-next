# frozen_string_literal: true

# Migration to add attachments_updated_at column to namespaces table
class AddAttachmentsUpdatedAtToNamespace < ActiveRecord::Migration[7.2]
  def change
    add_column :namespaces, :attachments_updated_at, :datetime
  end
end
