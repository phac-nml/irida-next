# frozen_string_literal: true

# Migration to add Persistent Unique Identifier column to Namespace model and remove from the Project model.
class AddPuidToNamespace < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength
    add_column :namespaces, :puid, :string

    reversible do |dir|
      dir.up do
        Namespace.with_deleted.each do |namespace|
          if namespace.type == Namespaces::ProjectNamespace.sti_name
            project = Project.with_deleted.find_by(namespace:)
            namespace.update!(puid: project.puid)
          else
            namespace.update!(puid: Irida::PersistentUniqueId.generate(namespace, time: namespace.created_at))
          end
        end
        change_column :namespaces, :puid, :string, null: false
      end
    end

    remove_index :projects, :puid, unique: true
    remove_column :projects, :puid, :string

    add_index :namespaces, :puid, unique: true
  end
end
