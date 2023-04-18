# frozen_string_literal: true

# Policy for samples
class SamplePolicy < ApplicationPolicy
  def show?
    (record.project.creator == user) || record.project.namespace.project_members.find_by(user:) ||
      record.project.namespace.parent == user
  end

  def destroy?
    (record.project.creator == user) || record.project.namespace.owners.include?(user) ||
      record.project.namespace.parent == user
  end

  def update?
    (record.project.creator == user) || record.project.namespace.owners.include?(user) ||
      record.projeect.namespace.parent == user
  end

  scope_for :relation do |relation, project_id|
    relation.where(project_id)
  end
end
