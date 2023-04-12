# Policies for groups
class GroupPolicy < ApplicationPolicy
  def show?
    (record.owner == user) || record.group_members.find_by(user:)
  end

  def new?
    record.parent.nil? || (record.owner == user) || record.owners.include?(user) || record.parent.owners.include?(user)
  end

  def create?
    (record.owner == user) || record.owners.include?(user) || record.parent&.owners&.include?(user)
  end

  def destroy?
    (record.owner == user) || record.owners.include?(user) || record.parent&.owners&.include?(user)
  end

  def update?
    (record.owner == user) || record.owners.include?(user) || record.parent&.owners&.include?(user)
  end

  def edit?
    (record.owner == user) || record.owners.include?(user) || record.parent&.owners&.include?(user)
  end

  scope_for :relation do |relation|
    relation.include_route.where(owner: user)
  end
end
