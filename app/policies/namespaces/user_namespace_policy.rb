# frozen_string_literal: true

module Namespaces
  # Policy for authorization under user_namespace
  class UserNamespacePolicy < NamespacePolicy
    alias_rule :new?, :create?, to: :allowed_to_modify_projects_under_namespace?

    def allowed_to_modify_projects_under_namespace?
      return true if record.owner == user

      can_modify?(record)
    end

    def transfer_to_namespace?
      return true if record.owner == user

      false
    end
  end
end
