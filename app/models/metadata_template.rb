# frozen_string_literal: true

# MetadataTemplate represents a template for structured metadata fields
class MetadataTemplate < ApplicationRecord
  include TrackActivity

  has_logidze
  acts_as_paranoid
  broadcasts_refreshes

  # Validations
  validates :name, presence: true

  # Associations
  belongs_to :namespace
  belongs_to :created_by, class_name: 'User'

  has_many :metadata_fields, dependent: :destroy
end
