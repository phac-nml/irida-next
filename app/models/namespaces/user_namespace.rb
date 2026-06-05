# frozen_string_literal: true

module Namespaces
  # Namespace for Users
  class UserNamespace < Namespace
    has_many :project_namespaces,
             lambda {
               where(type: Namespaces::ProjectNamespace.sti_name)
             }, class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

    before_save :validate_public_namespace_type, if: -> { public_changed? }

    def self.sti_name
      'User'
    end

    def self.model_prefix
      'USR'
    end

    def validate_public_namespace_type
      errors.add(:base, 'User namespaces cannot be public')
      throw(:abort)
    end
  end
end
