# frozen_string_literal: true

module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < ApplicationPolicy
    alias_rule :new?, :create?, :update?, to: :allowed_to_modify_project_namespace?
    alias_rule :destroy?, to: :allowed_to_destroy?

    def allowed_to_view_members?
      return true if record.parent.owner == user

      can_view?(record)
    end

    def allowed_to_modify_project_namespace?
      return true if record.parent.owner == user

      can_modify?(record)
    end

    def allowed_to_destroy?
      return true if record.parent.owner == user

      can_destroy?(record)
    end

    def allowed_to_modify_members?
      return true if record.parent.owner == user

      can_modify_members?(record)
    end
  end
end
