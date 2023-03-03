# frozen_string_literal: true

# entity class for Member
class Member < ApplicationRecord
  belongs_to :user
  belongs_to :namespace, autosave: true

  validates :role, presence: true
  validates :metadata_role, presence: true, unless: :skip_metadata_role_validation?
  validates :user_id, uniqueness: { scope: :namespace_id }

  validate :validate_namespace

  def validate_namespace
    # Only Groups and Projects should have members
    return if %w[Group Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have members')
  end

  def skip_metadata_role_validation?
    # Skip validation of metadata_role if not in the project namespace
    namespace.type != 'Project'
  end
end
