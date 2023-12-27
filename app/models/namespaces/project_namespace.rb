# frozen_string_literal: true

module Namespaces
  # Namespace for Projects
  class ProjectNamespace < Namespace
    has_one :project, inverse_of: :namespace, foreign_key: :namespace_id, dependent: :destroy
    has_many :project_members, foreign_key: :namespace_id, inverse_of: :project_namespace,
                               class_name: 'Member', dependent: :destroy
    has_many :users, through: :project_members

    has_many :shared_with_group_links, # rubocop:disable Rails/InverseOf
             lambda {
               where(namespace_type: Namespaces::ProjectNamespace.sti_name)
             },
             foreign_key: :namespace_id, class_name: 'NamespaceGroupLink',
             dependent: :destroy do
      def of_ancestors
        ns = proxy_association.owner

        NamespaceGroupLink.where(namespace_id: ns.parent.self_and_ancestor_ids)
      end

      def of_ancestors_and_self
        ns = proxy_association.owner

        source_ids = [ns.id] + ns.parent.self_and_ancestor_ids

        NamespaceGroupLink.where(namespace_id: source_ids)
      end
    end

    has_many :shared_with_groups, through: :shared_with_group_links, source: :group

    def self.sti_name
      'Project'
    end

    def update_metadata_summary_by_update_service(metadata_to_delete, metadata_to_add)
      namespaces_to_update = self_and_parents

      unless metadata_to_delete.empty?
        namespaces_to_update.each do |namespace|
          subtract_one_from_metadata_summary(namespace, metadata_to_delete)
        end
      end

      unless metadata_to_add.empty?
        namespaces_to_update.each do |namespace|
          add_one_to_metadata_summary(namespace, metadata_to_add)
        end
      end
      namespaces_to_update.each(&:save)
    end

    private

    def self_and_parents
      namespaces = [self]
      namespaces += parent.self_and_ancestors unless parent.type == 'User'
      namespaces
    end

    def subtract_one_from_metadata_summary(namespace, metadata_to_delete)
      metadata_to_delete.each do |metadata_field, _v|
        if namespace.metadata_summary[metadata_field] == 1
          namespace.metadata_summary.delete(metadata_field)
        else
          namespace.metadata_summary[metadata_field] -= 1
        end
      end
    end

    def add_one_to_metadata_summary(namespace, metadata_to_add)
      metadata_to_add.each do |metadata_field, _v|
        if namespace.metadata_summary.key?(metadata_field)
          namespace.metadata_summary[metadata_field] += 1
        else
          namespace.metadata_summary[metadata_field] = 1
        end
      end
    end
  end
end
