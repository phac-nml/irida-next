# frozen_string_literal: true

# Base policy for namespace authorization
class NamespacePolicy < ApplicationPolicy
  scope_for :relation, :manageable do |relation|
    relation
      .where(
        type: [Namespaces::UserNamespace.sti_name],
        owner: user
      ).self_and_descendants.where.not(type: Namespaces::ProjectNamespace.sti_name).include_route
      .or(
        relation.where(
          type: [Group.sti_name],
          id:
            Member.where(
              user:,
              access_level: [
                Member::AccessLevel::MAINTAINER,
                Member::AccessLevel::OWNER
              ]
            ).select(:namespace_id)
        ).self_and_descendants.where.not(type: Namespaces::ProjectNamespace.sti_name)
      ).include_route
  end
end
