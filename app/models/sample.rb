# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[name project_id] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def metadata_with_provenance
    sample_metadata = []
    metadata.each do |metadata_field, value|
      provider = if metadata_provenance[metadata_field]['source'] == 'user'
                   User.find(metadata_provenance[metadata_field]['id']).email
                 else
                   "Analysis #{metadata_provenance[metadata_field]['id']}"
                 end
      sample_metadata << { metadata_field:, value:, provider:,
                           last_modified: metadata_provenance[metadata_field]['updated_at'] }
    end
    sample_metadata
  end
end
