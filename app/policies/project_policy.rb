# Policies for projects
class ProjectPolicy < ApplicationPolicy
  def show?
    (record.creator == user) || record.namespace.project_members.find_by(user:) || record.namespace.parent == user
  end

  def new?
    (record.creator == user) || record.namespace.owners.include?(user) || record.namespace.parent == user
  end

  def create?
    (record.creator == user) || record.namespace.owners.include?(user) || record.namespace.parent == user
  end

  def destroy?
    (record.creator == user) || record.namespace.owners.include?(user) || record.namespace.parent == user
  end

  def edit?
    (record.creator == user) || record.namespace.owners.include?(user) || record.namespace.parent == user
  end

  def update?
    (record.creator == user) || record.namespace.owners.include?(user) || record.namespace.parent == user
  end

  def transfer?
    (record.creator == user) || record.namespace.parent == user
  end

  def activity?
    (record.creator == user) || record.namespace.project_members.find_by(user:) || record.namespace.parent == user
  end

  scope_for :relation do |relation|
    relation.include_route.where(creator: user)
  end
end
