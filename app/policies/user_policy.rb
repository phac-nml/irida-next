# frozen_string_literal: true

# Policy for profiles authorization
class UserPolicy < ApplicationPolicy
  alias_rule :update?, :edit?, :destroy?, :revoke?, to: :manage?
  alias_rule :show?, :index?, to: :view?
  alias_rule :new?, to: :create?

  def manage?
    return true if record == user

    details[:name] = record.email
    false
  end

  def create?
    return true if record == user

    details[:name] = record.email
    false
  end

  def view?
    return true if record == user

    details[:name] = record.email
    false
  end
end
