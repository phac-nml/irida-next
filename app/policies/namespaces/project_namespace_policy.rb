# frozen_string_literal: true

module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < ApplicationPolicy
    alias_rule :new?, :create?, :destroy?, to: :allowed_to_modify_project_namespace?

    def allowed_to_view_members?
      return true if record.parent.owner == user

      can_view?(record)
    end

    def allowed_to_modify_project_namespace?
      return true if record.parent.owner == user

      can_modify?(record)
    end
  end
end
