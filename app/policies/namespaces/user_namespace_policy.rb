# frozen_string_literal: true

module Namespaces
  # Policy for authorization under user_namespace
  class UserNamespacePolicy < NamespacePolicy
    alias_rule :new?, :create?, to: :manage?

    def manage?
      return true if record.owner == user
      return true if can_modify?(record) == true

      details[:name] = record.name
      false
    end

    def transfer_to_namespace?
      return true if record.owner == user

      details[:name] = record.name
      false
    end
  end
end
