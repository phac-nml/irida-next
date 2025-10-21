# frozen_string_literal: true

# Policy for profiles authorization
class UserPolicy < ApplicationPolicy
  def create?
    true if record == user
  end

  def destroy?
    true if record == user
  end

  def edit?
    true if record == user
  end

  def index?
    true if record == user
  end

  def new?
    true if record == user
  end

  def revoke?
    true if record == user
  end

  def read?
    return true if record == user

    details[:name] = record.email
    false
  end

  def update?
    return true if record == user

    details[:name] = record.email
    false
  end

  def edit_password?
    # Passwords on OmniAuth Users is not allowed
    update? && user.provider.nil?
  end

  def generate_bot_personal_access_token?
    true if record == user
  end
end
