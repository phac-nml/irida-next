# frozen_string_literal: true

module Namespaces
  # Namespace for Users
  class UserNamespace < Namespace
    has_many :project_namespaces, foreign_key: :parent_id, inverse_of: :parent,
                                  class_name: 'Namespaces::ProjectNamespace', dependent: :destroy

    validate :validate_public_namespace_type, if: -> { public_changed? }

    def self.sti_name
      'User'
    end

    def self.model_prefix
      'USR'
    end

    def validate_public_namespace_type
      errors.add(:public, :invalid)
    end
  end
end
