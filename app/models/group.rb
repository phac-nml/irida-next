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

  has_many :shared_group_links, foreign_key: :shared_with_group_id, class_name: 'GroupGroupLink', dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :shared_with_group_links, foreign_key: :shared_group_id, class_name: 'GroupGroupLink', dependent: :destroy do # rubocop:disable Rails/InverseOf
    def of_ancestors
      group = proxy_association.owner

      return GroupGroupLink.none unless group.has_parent?

      GroupGroupLink.where(shared_group_id: group.ancestor_ids)
    end

    def of_ancestors_and_self
      group = proxy_association.owner

      source_ids = group.self_and_ancestor_ids

      GroupGroupLink.where(shared_group_id: source_ids)
    end
  end
  has_many :shared_groups, through: :shared_group_links, source: :shared_group
  has_many :shared_with_groups, through: :shared_with_group_links, source: :shared_with_group

  def self.sti_name
    'Group'
  end
end
