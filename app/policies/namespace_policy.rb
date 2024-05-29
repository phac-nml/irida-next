# frozen_string_literal: true

# Base policy for namespace authorization
class NamespacePolicy < ApplicationPolicy
  scope_for :relation, :manageable do |relation|
    relation.with(
      personal_namespaces: relation.where(id: user.namespace&.id).select(:id),
      membership_in_namespaces: relation.where(type: Group.sti_name,
                                               id: user.members.not_expired.joins(:namespace).where(
                                                 access_level: Member::AccessLevel.manageable,
                                                 namespace: { type: Group.sti_name }
                                               ).select(:namespace_id)).self_and_descendants.where.not(
                                                 type: Namespaces::ProjectNamespace.sti_name
                                               ).select(:id),
      linked_namespaces: relation.where(id: NamespaceGroupLink.where(
        group: user.groups.where(id: user.members.not_expired.joins(:namespace)
        .where(access_level: Member::AccessLevel.manageable, namespace: { type: Group.sti_name })
        .select(:namespace_id)).self_and_descendants,
        group_access_level: Member::AccessLevel.manageable,
        namespace_type: Group.sti_name
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
