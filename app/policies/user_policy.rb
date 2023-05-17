# frozen_string_literal: true

# Policy for profiles authorization
class UserPolicy < ApplicationPolicy
  alias_rule :show?, :create?, :update?, :edit?, :index?, :destroy?, :revoke?, to: :manage?

  def manage?
    return true if record == user

    details[:name] = record.email
    false
  end
end
