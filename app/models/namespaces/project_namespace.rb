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

    def metadata_sort(metadata_field, direction = 'asc')
      return [] unless %w[asc desc].include?(direction.downcase)

      project = self.project
      # Sample.where('project_id = :project_id and metadata @> :metadata', metadata: { metadatafield1: 10 }.to_json,
      #                                                                    project_id: project.id)
      # Sample.where('project_id = :project_id and metadata ? :metadata_key', metadata_key: 'metadatafield1',
      #                                                                       project_id: project.id)
      Sample.where('project_id = :project_id and metadata ? :metadata_key',
                   metadata_key: metadata_field,
                   project_id: project.id).order("metadata #{direction}")
    end
  end
end
