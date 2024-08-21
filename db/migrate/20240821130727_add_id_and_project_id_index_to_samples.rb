# frozen_string_literal: true

# Add Id and Project Id index to Samples table
class AddIdAndProjectIdIndexToSamples < ActiveRecord::Migration[7.2]
  def change
    add_index :samples, %i[id project_id], unique: true
  end
end
