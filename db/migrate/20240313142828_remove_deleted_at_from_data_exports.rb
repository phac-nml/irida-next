# frozen_string_literal: true

# Remove deleted_at from DataExports
class RemoveDeletedAtFromDataExports < ActiveRecord::Migration[7.1]
  def change
    remove_column :data_exports, :deleted_at, :datetime
  end
end
