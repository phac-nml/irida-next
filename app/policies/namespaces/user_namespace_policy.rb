# frozen_string_literal: true

module Namespaces
  # Policy for authorization under user_namespace
  class UserNamespacePolicy < NamespacePolicy
    alias_rule :new?, :create?, to: :allowed_to_modify_projects_under_namespace?
    alias_rule :destroy?, to: :allowed_to_destroy?

    def allowed_to_modify_projects_under_namespace?
      return true if record.owner == user

      can_modify?(record)
    end

    def allowed_to_destroy?
      return true if record.owner == user

      can_destroy?(record)
    end

    def transfer_to_namespace?
      return true if record.owner == user
      return true if record.children_allowed?

      false
    end
  end
end
