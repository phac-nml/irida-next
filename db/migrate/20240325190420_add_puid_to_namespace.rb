# frozen_string_literal: true

# Migration to add Persistent Unique Identifier column to Namespace model and remove from the Project model.
class AddPuidToNamespace < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    add_column :namespaces, :puid, :string

    reversible do |dir|
      dir.up do
        Namespace.with_deleted.where.not(type: 'Project').each do |namespace|
          next unless namespace.type != Namespaces::ProjectNamespace.sti_name

          puid = Irida::PersistentUniqueId.generate(namespace, time: namespace.created_at)

          execute <<-SQL.squish
              UPDATE namespaces SET puid = '#{puid}' WHERE id = '#{namespace.id}'
          SQL
        end

        execute <<~SQL.squish
          UPDATE namespaces
          set puid = projects.puid
          FROM projects
          WHERE projects.namespace_id = namespaces.id
        SQL

        change_column :namespaces, :puid, :string, null: false
      end
    end

    remove_index :projects, :puid, unique: true
    remove_column :projects, :puid, :string

    add_index :namespaces, :puid, unique: true
  end
end
