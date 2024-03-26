# frozen_string_literal: true

module Namespaces
  # Namespace for Users
  class UserNamespace < Namespace
    has_many :project_namespaces,
             lambda {
               where(type: Namespaces::ProjectNamespace.sti_name)
             }, class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

    def self.sti_name
      'User'
    end

    def self.model_prefix
      'USR'
    end
  end
end
