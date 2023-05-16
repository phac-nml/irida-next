# frozen_string_literal: true

# Policy for profiles authorization
class UserPolicy < ApplicationPolicy
  alias_rule :show?, :create?, :update?, :edit?, :index?, :destroy?, :revoke?, to: :profile_owner?

  def profile_owner?
    record == user
  end
end
