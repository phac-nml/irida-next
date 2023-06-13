# frozen_string_literal: true

# Base policy for member authorization
class MemberPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]
    direct_namespace_members = relation.where(namespace:).uniq(&:user_id)

    namespace_ids = if namespace.project_namespace?
                      namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    if direct_namespace_members.count.positive?
      inherited_namespace_members = relation.where('namespace_id IN (?) AND user_id NOT IN (?)',
                                                   namespace_ids,
                                                   direct_namespace_members.pluck(:user_id)).uniq(&:user_id)
    else
      inherited_namespace_members = relation.where(namespace_id: namespace_ids).uniq(&:user_id)
    end

    Member.where(id: direct_namespace_members.map(&:id)).or(Member.where(id: inherited_namespace_members.map(&:id)))
  end
end
