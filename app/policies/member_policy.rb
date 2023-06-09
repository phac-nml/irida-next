# frozen_string_literal: true

# Base policy for member authorization
class MemberPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]

    if namespace.project_namespace?
      direct_namespace_members = relation.where(namespace:)

      if direct_namespace_members.count.positive?
        inherited_namespace_members = relation.where('namespace_id IN (?) AND user_id NOT IN (?)',
                                                     namespace.parent&.self_and_ancestor_ids,
                                                     direct_namespace_members.pluck(:user_id))
      else
        inherited_namespace_members = relation.where(namespace_id: namespace.parent&.self_and_ancestor_ids)
      end

      direct_namespace_members.or(inherited_namespace_members)
    elsif namespace.group_namespace?
      relation.where(namespace_id: namespace.self_and_ancestor_ids)
    end
  end
end
