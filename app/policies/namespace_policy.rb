# frozen_string_literal: true

# Base policy for namespace authorization
class NamespacePolicy < ApplicationPolicy
  # rubocop:disable-next Metrics/BlockLength, Metrics/ParameterLists
  scope_for :relation do |relation,
                          access_level: Member::AccessLevel.accessible,
                          include_project_namespaces: false,
                          include_route: true,
                          include_shared_links: true,
                          use_traversal_ids: true|
    type = [Group.sti_name, Namespaces::UserNamespace.sti_name]
    type << Namespaces::ProjectNamespace.sti_name if include_project_namespaces

    # The user's personal namespace and the namespaces they have direct membership
    # access to are combined into a single root set before expanding to
    # self + descendants, so the traversal_ids overlap check (and its GIN index
    # scan) only needs to run once instead of once per root set.
    accessible_root_namespaces = Namespace.where(id: user.namespace&.id)
                                          .or(Namespace.where(
                                                id: user.members.not_expired.with_access_level(access_level)
                                                        .select(:namespace_id)
                                              ))

    scope = relation
            .with(
              # 1. Accessible namespace IDs for the user: their personal namespace and
              #    namespaces they have direct membership access to, plus all descendants
              accessible_namespaces: self_and_descendants_of_type(
                accessible_root_namespaces, type, use_traversal_ids
              ).select(:id),
              # 2. Accessible linked namespaces for the user based on group links
              accessible_linked_namespaces:
                if include_shared_links
                  self_and_descendants_of_type(
                    Namespace.where(id: NamespaceGroupLink
                                        .not_expired
                                        .where(Arel.sql('group_id IN (SELECT id FROM accessible_namespaces)'))
                                        .with_group_access_level(access_level)
                                        .select(:namespace_id)),
                    type, use_traversal_ids
                  ).select(:id)
                else
                  Namespace.none.select(:id)
                end
            ).where(
              Arel.sql(
                'namespaces.id IN (
                  SELECT id FROM accessible_namespaces
                  UNION ALL
                  SELECT id FROM accessible_linked_namespaces
                )'
              )
            )
    scope = scope.include_route if include_route
    scope
  end

  scope_for :relation, :manageable do |relation, include_project_namespaces: false, include_route: true,
                                       use_traversal_ids: true|
    authorized_scope(relation, type: :relation,
                               scope_options: { access_level: Member::AccessLevel.manageable,
                                                include_project_namespaces: include_project_namespaces,
                                                include_route: include_route,
                                                use_traversal_ids: use_traversal_ids })
  end

  private

  # Resolves self + descendants of `type` for `relation`, via either the
  # traversal_ids-based class scope (the default) or the route-based
  # equivalent (`use_traversal_ids: false`) - kept so this listing scope can
  # be benchmarked against both strategies (see
  # lib/benchmarks/namespace_listing_policy_scope.rb) and as a manual
  # fallback switch.
  def self_and_descendants_of_type(relation, type, use_traversal_ids)
    scoped = use_traversal_ids ? relation.self_and_descendants : relation.route_based_self_and_descendants
    scoped.where(type: type)
  end
end
