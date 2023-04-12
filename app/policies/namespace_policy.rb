# Policies for groups
class NamespacePolicy < ApplicationPolicy
  def index?
    true
  end

  def new?
    (record.owner == user) || record.owners.include?(user) || record.parent.owners.include?(user)
  end

  def create?
    (record.owner == user) || record.owners.include?(user) || record.parent.owners.include?(user)
  end

  def destroy?
    (record.owner == user) || record.owners.include?(user) || record.parent.owners.include?(user)
  end
end
