module Namespaces
  # Policies for project members
  class ProjectNamespacePolicy < ApplicationPolicy
    def index?
      (record.owner == user) || record.project_members.find_by(user:)
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
end
