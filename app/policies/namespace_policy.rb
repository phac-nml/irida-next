# frozen_string_literal: true

# Base policy for namespace authorization
class NamespacePolicy < ApplicationPolicy
  scope_for :relation, :manageable do |relation|
    relation.with(
      personal_namespaces: relation.where(type: [Namespaces::UserNamespace.sti_name],
                                          owner: user).self_and_descendants
                                          .where.not(type: Namespaces::ProjectNamespace.sti_name).select(:id),
      membership_in_namespaces: relation.where(
        type: [Group.sti_name],
        id: user.members.where(access_level: Member::AccessLevel.manageable).select(:namespace_id)
      ).self_and_descendants.where.not(type: Namespaces::ProjectNamespace.sti_name).select(:id),
      linked_namespaces: relation.where(id: NamespaceGroupLink.where(
        group_access_level: Member::AccessLevel.manageable,
        group: user.members.joins(:namespace).where(
          namespace: { type: Group.sti_name },
          access_level: Member::AccessLevel.manageable
        ).select(:namespace_id)
      ).not_expired.select(:namespace_id)).self_and_descendants.where.not(type: Namespaces::ProjectNamespace.sti_name)
      .select(:id)
    ).where(
      Arel.sql(
        'namespaces.id in (select * from personal_namespaces)
        or namespaces.id in (select * from membership_in_namespaces)
        or namespaces.id in (select * from linked_namespaces)'
      )
    ).include_route
  end
end
