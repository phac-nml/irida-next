# frozen_string_literal: true

# migration to add samples count to namespaces table
class AddSamplesCountToNamespaces < ActiveRecord::Migration[7.2]
  def change
    add_column :namespaces, :samples_count, :integer
  end
end
