# frozen_string_literal: true

# migration to add deleted_at column to samples
class AddDeletedAtToSamples < ActiveRecord::Migration[7.0]
  def change
    add_column :samples, :deleted_at, :datetime
    add_index :samples, :deleted_at
  end
end
