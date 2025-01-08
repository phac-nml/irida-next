# frozen_string_literal: true

# MetadataTemplate represents a template for structured metadata fields
class MetadataTemplate < ApplicationRecord
  include TrackActivity

  has_logidze
  acts_as_paranoid

  # Associations
  belongs_to :created_by, class_name: 'User'

  # Validations
  validates :name, presence: true, uniqueness: { scope: [:namespace_id] }
  validates :description, length: { maximum: 1000 }

  belongs_to :namespace, autosave: true

  belongs_to :group, optional: true, foreign_key: :namespace_id # rubocop:disable Rails/InverseOf
  belongs_to :project_namespace, optional: true, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  validate :validate_namespace

  private

  def validate_namespace
    # Only Groups and Projects should have metadata templates
    return if %w[Group Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have metadata templates')
  end
end
