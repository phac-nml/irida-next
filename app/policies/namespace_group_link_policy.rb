# frozen_string_literal: true

# Base policy for namespace group link authorization
class NamespaceGroupLinkPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]
    use_traversal_ids = options.fetch(:use_traversal_ids, true)

    namespace_ids = ancestor_namespace_ids(namespace, use_traversal_ids)

    most_specific_link_ids = if use_traversal_ids
                               most_specific_link_ids_via_traversal_ids(namespace, namespace_ids)
                             else
                               most_specific_link_ids_via_routes(namespace, namespace_ids)
                             end

    relation.where(id: most_specific_link_ids)
  end

  private

  # Resolve the self-and-ancestor namespace ids for `namespace`. When
  # traversal_ids are available (the default), the namespace's
  # `traversal_ids` column already holds its full root-to-self id chain, so
  # it is returned directly - avoiding the 1-2 extra queries the
  # query-based branch below would otherwise fire (a parent load plus an
  # ancestor lookup for a project namespace). The query-based fallback is
  # kept for the routes strategy (use_traversal_ids: false) and for
  # namespaces whose traversal_ids have not been backfilled yet.
  def ancestor_namespace_ids(namespace, use_traversal_ids)
    return namespace.traversal_ids if use_traversal_ids && namespace.use_traversal_ids?

    if namespace.project_namespace?
      [namespace.id] + namespace.parent&.self_and_ancestor_ids
    else
      namespace.self_and_ancestor_ids
    end
  end

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
