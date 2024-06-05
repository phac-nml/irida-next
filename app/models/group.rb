# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  include History

  has_many :group_members, foreign_key: :namespace_id, inverse_of: :group,
                           class_name: 'Member', dependent: :destroy
  has_many :project_namespaces,
           lambda {
             where(type: Namespaces::ProjectNamespace.sti_name)
           },
           class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :users, through: :group_members

  has_many :namespace_bots, foreign_key: :namespace_id, inverse_of: :namespace,
                            class_name: 'NamespaceBot', dependent: :destroy

  has_many :bots, through: :namespace_bots, source: :user

  has_many :shared_group_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Group.sti_name)
           },
           foreign_key: :group_id, class_name: 'NamespaceGroupLink', dependent: :destroy
  has_many :shared_project_namespace_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Namespaces::ProjectNamespace.sti_name)
           },
           foreign_key: :group_id, class_name: 'NamespaceGroupLink', dependent: :destroy

  has_many :shared_with_group_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Group.sti_name)
           },
           foreign_key: :namespace_id, class_name: 'NamespaceGroupLink',
           dependent: :destroy do
    def of_ancestors
      group = proxy_association.owner

      return NamespaceGroupLink.none unless group.has_parent?

      NamespaceGroupLink.where(namespace_id: group.ancestor_ids)
    end

    def of_ancestors_and_self
      group = proxy_association.owner

      source_ids = group.self_and_ancestor_ids

      NamespaceGroupLink.where(namespace_id: source_ids)
    end
  end
  has_many :shared_groups, through: :shared_group_links, source: :namespace
  has_many :shared_project_namespaces, through: :shared_project_namespace_links,
                                       class_name: 'Namespaces::ProjectNamespace', source: :namespace
  has_many :shared_projects, through: :shared_project_namespaces, class_name: 'Project', source: :project
  has_many :shared_with_groups, through: :shared_with_group_links, source: :group

  def self.sti_name
    'Group'
  end

  def self.model_prefix
    'GRP'
  end

  def metadata_fields
    metadata_fields = metadata_summary.keys

    shared_groups.each do |shared_group|
      metadata_fields.concat shared_group.metadata_summary.keys
    end

    shared_project_namespaces.each do |shared_project_namespace|
      metadata_fields.concat shared_project_namespace.metadata_summary.keys
    end

    metadata_fields.uniq
  end
end
