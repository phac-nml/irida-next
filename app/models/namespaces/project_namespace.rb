# frozen_string_literal: true

module Namespaces
  # Namespace for Projects
  class ProjectNamespace < Namespace
    include History

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

    def update_metadata_summary_by_update_service(deleted_metadata, added_metadata)
      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      subtract_from_metadata_summary_count(namespaces_to_update, deleted_metadata, true) unless deleted_metadata.empty?
      add_to_metadata_summary_count(namespaces_to_update, added_metadata, true) unless added_metadata.empty?
    end

    # self = the original parent of the transferred samples
    # new_project_id = the project ID receiving the new samples
    # transferred_samples_ids contains the IDs of the transferred samples
    def update_metadata_summary_by_sample_transfer(transferred_samples_ids, new_project_id) # rubocop:disable Metrics/AbcSize
      old_namespaces = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      new_project_namespace = Project.find(new_project_id).namespace
      new_namespaces =
        [new_project_namespace] +
        new_project_namespace.parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      transferred_samples_ids.each do |sample_id|
        sample = Sample.find(sample_id)
        next if sample.metadata.empty?

        subtract_from_metadata_summary_count(old_namespaces, sample.metadata, true)
        add_to_metadata_summary_count(new_namespaces, sample.metadata, true)
      end
    end

    def update_metadata_summary_by_sample_deletion(sample)
      return if sample.metadata.empty?

      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      subtract_from_metadata_summary_count(namespaces_to_update, sample.metadata, true)
    end

    def update_metadata_summary_by_sample_addition(sample)
      return if sample.metadata.empty?

      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      add_to_metadata_summary_count(namespaces_to_update, sample.metadata, true)
    end

    def self.model_prefix
      'PRJ'
    end
  end
end
