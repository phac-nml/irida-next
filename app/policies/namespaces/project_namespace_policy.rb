# frozen_string_literal: true

module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < NamespacePolicy
    alias_rule :new?, :create?, :update?, to: :manage?

    def manage?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if can_modify?(record) == true

      details[:name] = record.name
      false
    end
  end
end
