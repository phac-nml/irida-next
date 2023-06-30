# frozen_string_literal: true

# Base policy for member authorization
class MemberPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]

    namespace_ids = if namespace.project_namespace?
                      [namespace.id] + namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    relation.where(id: Member.joins(namespace: [:route])
                             .where(namespace_id: namespace_ids)
                             .order(user_id: :asc, 'routes.path': :desc)
                             .select('DISTINCT ON (user_id) members.id'))
  end
end
