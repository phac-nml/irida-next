# frozen_string_literal: true

# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  # Configure additional authorization contexts here
  # (`user` is added by default).
  #
  #   authorize :account, optional: true
  #
  # Read more about authorization context: https://actionpolicy.evilmartians.io/#/authorization_context

  # Define shared methods useful for most policies.
  # For example:
  #
  #  def owner?
  #    record.user_id == user.id
  #  end
  #

  def can_modify?(obj)
    Member.can_modify?(user, obj)
  end

  def can_view?(obj)
    Member.can_view?(user, obj)
  end

  def can_destroy?(obj)
    Member.can_destroy?(user, obj)
  end

  def can_transfer?(obj)
    Member.namespace_owners_include_user?(user, obj)
  end

  scope_for :relation, :manageable do |relation|
    relation
      .where(
        type: [Namespaces::UserNamespace.sti_name],
        owner: user
      ).self_and_descendants.where.not(type: Project.sti_name).include_route
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
        ).self_and_descendants.where.not(type: Project.sti_name)
      ).include_route
  end
end
