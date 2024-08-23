# frozen_string_literal: true

# Migration to add samples_count to Project
class AddSamplesCountToProjects < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :samples_count, :integer
  end
end
