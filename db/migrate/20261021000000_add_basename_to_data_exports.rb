# frozen_string_literal: true

# Add basename to data exports
class AddBasenameToDataExports < ActiveRecord::Migration[8.1]
  def change
    add_column :data_exports, :basename, :string
  end
end
