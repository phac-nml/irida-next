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

    def self_and_parents
      namespaces = [self]
      namespaces += parent.self_and_ancestors unless parent.type == 'User'
      namespaces
    end

    def update_metadata_summary_by_update_service(deleted_metadata, added_metadata)
      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      subtract_from_metadata_summary_count(namespaces_to_update, deleted_metadata, true) unless deleted_metadata.empty?
      add_to_metadata_summary_count(namespaces_to_update, added_metadata, true) unless added_metadata.empty?
    end

    def update_metadata_summary_by_sample_transfer(transferred_samples_ids, new_project_id)
      new_project = Project.find(new_project_id)
      transferred_samples_ids.each do |sample_id|
        sample = Sample.find(sample_id)
        unless sample.metadata.empty?
          subtract_sample_from_old_metadata_summary(sample)
          add_sample_to_new_metadata_summary(new_project, sample)
        end
      end
    end

    private

    def subtract_sample_from_old_metadata_summary(sample)
      namespaces_to_update = self_and_parents
      namespaces_to_update.each do |namespace|
        sample.metadata.each do |metadata_field, _v|
          subtract_from_metadata_summary(namespace, metadata_field, 1)
        end
      end
      namespaces_to_update.each(&:save)
    end

    def add_sample_to_new_metadata_summary(new_project, sample)
      namespaces_to_update = new_project.namespace.self_and_parents
      namespaces_to_update.each do |namespace|
        sample.metadata.each do |metadata_field, _v|
          add_to_metadata_summary(namespace, metadata_field, 1)
        end
      end
      namespaces_to_update.each(&:save)
    end
  end
end
