# frozen_string_literal: true

# migration to add metadata summary to namespaces table
class AddMetadataSummaryToNamespaces < ActiveRecord::Migration[7.1]
  def change
    add_column :namespaces, :metadata_summary, :jsonb, default: {}
  end
end
