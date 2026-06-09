# frozen_string_literal: true

module Namespaces
  # Namespace for Users
  class UserNamespace < Namespace
    has_many :project_namespaces,
             lambda {
               where(type: Namespaces::ProjectNamespace.sti_name)
             }, class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

    validate :validate_public_namespace_type, if: -> { public_changed? }

    def self.sti_name
      'User'
    end

    def self.model_prefix
      'USR'
    end

    def validate_public_namespace_type
      errors.add(:public, I18n.t('activerecord.errors.models.namespaces/user_namespace.attributes.public.invalid'))
      throw(:abort)
    end
  end
end
