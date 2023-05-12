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
end
