# frozen_string_literal: true

# Migration to add Persistent Unique Identifier column to Sample model
class AddPuidToSample < ActiveRecord::Migration[7.1]
  def change
    add_column :samples, :puid, :string

    reversible do |dir|
      dir.up do
        Sample.with_deleted.all.each do |sample|
          sample.update!(puid: Irida::PersistentUniqueId.generate(sample, time: sample.created_at))
        end
        change_column :samples, :puid, :string, null: false
      end
    end

    add_index :samples, :puid, unique: true
  end
end
