# frozen_string_literal: true

module Namespaces
  # Policy for authorization under user_namespace
  class UserNamespacePolicy < NamespacePolicy
    def create?
      return true if record.owner == user

      details[:name] = record.name
      false
    end

    def read?
      return true if record.owner == user

      details[:name] = record.name
      false
    end

    def transfer_into_namespace?
      return true if record.owner == user

      details[:name] = record.name
      false
    end
  end
end
