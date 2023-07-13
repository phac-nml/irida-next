# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  has_many :group_members, foreign_key: :namespace_id, inverse_of: :group,
                           class_name: 'Member', dependent: :destroy
  has_many :project_namespaces,
           lambda {
             where(type: Namespaces::ProjectNamespace.sti_name)
           },
           class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :users, through: :group_members

  has_many :group_links, foreign_key: :namespace_id, class_name: 'NamespaceGroupLink', # rubocop:disable Rails/InverseOf
                         dependent: :destroy
  has_many :namespace_links, foreign_key: :group_id, class_name: 'NamespaceGroupLink', # rubocop:disable Rails/InverseOf
                             dependent: :destroy do
    def of_ancestors
      group = proxy_association.owner

      return NamespaceGroupLink.none unless group.has_parent?

      NamespaceGroupLink.where(group_id: group.ancestor_ids)
    end

    def of_ancestors_and_self
      group = proxy_association.owner

      source_ids = group.self_and_ancestor_ids

      NamespaceGroupLink.where(group_id: source_ids)
    end
  end
  has_many :shared_groups, through: :group_links, source: :group
  has_many :shared_with_namespaces, through: :namespace_links, source: :namespace

  def self.sti_name
    'Group'
  end
end
