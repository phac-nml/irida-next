# frozen_string_literal: true

# Base policy for namespace authorization
class NamespacePolicy < ApplicationPolicy
  # rubocop:disable-next Metrics/BlockLength
  scope_for :relation do |relation,
                          access_level: Member::AccessLevel.accessible,
                          include_route: true,
                          include_shared_links: true|
    scope = relation
            .with(
              user_namespaces: Namespace
                .where(id: user.namespace&.id)
                .self_and_descendant_ids,
              # 1. Accessible namespace IDs for the user based on their memberships
              accessible_namespaces: Namespace
                .where(id: user.members.not_expired.with_access_level(access_level).select(:namespace_id))
                .self_and_descendant_ids,
              # 5. Accessible linked namespaces for the user based on group links
              accessible_linked_namespaces:
                if include_shared_links
                  Namespace
                    .where(id: NamespaceGroupLink
                      .not_expired
                      .where(Arel.sql('group_id IN (SELECT id FROM accessible_namespaces)'))
                      .with_group_access_level(access_level)
                      .select(:namespace_id))
                    .self_and_descendant_ids
                else
                  Namespace.none.select(:id)
                end
            ).where(
              Arel.sql(
                'namespaces.id IN (
                  SELECT id FROM user_namespaces
                  UNION ALL
                  SELECT id FROM accessible_namespaces
                  UNION ALL
                  SELECT id FROM accessible_linked_namespaces
                )'
              )
            )
    scope = scope.include_route if include_route
    scope
  end

  scope_for :relation, :manageable do |relation|
    authorized_scope(relation, type: :relation, scope_options: { access_level: Member::AccessLevel.manageable })
  end
end
