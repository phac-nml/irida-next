# frozen_string_literal: true

# MetadataTemplate represents a template for structured metadata fields
class MetadataTemplate < ApplicationRecord
  include TrackActivity

  has_logidze
  acts_as_paranoid
  broadcasts_refreshes

  # Associations
  belongs_to :namespace
  belongs_to :created_by, class_name: 'User'

  # Validations
  validates :name, presence: true, uniqueness: { scope: [:namespace_id] }
  validates :description, length: { maximum: 1000 }
  # validates :namespace_type,
  #           inclusion: {
  #             in: [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
  #           }
end
