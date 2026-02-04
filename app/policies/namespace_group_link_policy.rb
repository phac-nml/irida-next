# frozen_string_literal: true

# Base policy for namespace group link authorization
class NamespaceGroupLinkPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]

    namespace_ids = if namespace.project_namespace?
                      [namespace.id] + namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    relation.where(id: NamespaceGroupLink.joins(namespace: [:route])
                       .where(namespace_id: namespace_ids)
                       .where.not(group_id: namespace.id)
                       .order(group_id: :asc, 'routes.path': :desc)
                       .select('DISTINCT ON (group_id) namespace_group_links.id'))
  end
end
