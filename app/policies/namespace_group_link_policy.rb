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

    most_specific_link_ids = if options.fetch(:use_traversal_ids, true)
                               most_specific_link_ids_via_traversal_ids(namespace, namespace_ids)
                             else
                               most_specific_link_ids_via_routes(namespace, namespace_ids)
                             end

    relation.where(id: most_specific_link_ids)
  end

  private

  # Picks each group's single most-specific link (the deepest namespace
  # within namespace_ids) using traversal_ids - no routes join required.
  def most_specific_link_ids_via_traversal_ids(namespace, namespace_ids)
    NamespaceGroupLink.joins(:namespace)
                      .where(namespace_id: namespace_ids)
                      .where.not(group_id: namespace.id)
                      .order(:group_id)
                      .order(Arel.sql('CARDINALITY(namespaces.traversal_ids) DESC'))
                      .select('DISTINCT ON (group_id) namespace_group_links.id')
  end

  # Equivalent to the method above, via a routes join and ordering by
  # routes.path - kept for callers that pass use_traversal_ids: false.
  def most_specific_link_ids_via_routes(namespace, namespace_ids)
    NamespaceGroupLink.joins(namespace: [:route])
                      .where(namespace_id: namespace_ids)
                      .where.not(group_id: namespace.id)
                      .order(group_id: :asc, 'routes.path': :desc)
                      .select('DISTINCT ON (group_id) namespace_group_links.id')
  end
end
