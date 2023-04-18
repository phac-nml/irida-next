# frozen_string_literal: true

# Policies for profiles
class ProfilesPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def destroy?
    true
  end

  def update?
    true
  end
end
