# frozen_string_literal: true

module Namespaces
  # Namespace for Users
  class UserNamespace < Namespace
    def self.sti_name
      'User'
    end
  end
end
