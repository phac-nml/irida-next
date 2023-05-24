# frozen_string_literal: true

# Policy for profiles authorization
class UserPolicy < ApplicationPolicy
  def update?
    return true if record == user
  end

  def edit?
    return true if record == user
  end

  def destroy?
    return true if record == user
  end

  def revoke?
    return true if record == user
  end

  def show?
    return true if record == user

    details[:name] = record.email
    false
  end

  def index?
    return true if record == user
  end

  def new?
    return true if record == user
  end

  def create?
    return true if record == user
  end
end
