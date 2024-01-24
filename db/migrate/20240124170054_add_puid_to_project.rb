# frozen_string_literal: true

# Migration to add Persistent Unique Identifier column to Project model
class AddPuidToProject < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :puid, :string

    reversible do |dir|
      dir.up do
        Project.all.each do |project|
          project.update!(puid: Irida::PersistentUniqueId.generate(project, time: project.created_at))
        end
        change_column :projects, :puid, :string, null: false
      end
    end

    add_index :projects, :puid, unique: true
  end
end
