# frozen_string_literal: true

module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < NamespacePolicy
    alias_rule :new?, :create?, :update?, to: :allowed_to_modify_project_namespace?
    alias_rule :index?, to: :allowed_to_view_project_namespace?
    alias_rule :destroy?, to: :allowed_to_destroy?

    def allowed_to_modify_project_namespace?
      return true if record.parent.user_namespace? && record.parent.owner == user

      can_modify?(record)
    end

    def allowed_to_view_project_namespace?
      return true if record.parent.user_namespace? && record.parent.owner == user

      can_view?(record)
    end

    def allowed_to_destroy?
      return true if record.parent.user_namespace? && record.parent.owner == user

      can_destroy?(record)
    end
  end
end
