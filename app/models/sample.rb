# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  has_logidze
  acts_as_paranoid

  include HasPuid

  belongs_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[name project_id] }

  def self.model_prefix
    'SAM'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def metadata_with_provenance
    sample_metadata = []
    metadata.each do |key, value|
      source = if metadata_provenance[key]['source'] == 'user'
                 User.find(metadata_provenance[key]['id']).email
               else
                 "#{I18n.t('models.sample.analysis')} #{metadata_provenance[key]['id']}"
               end
      sample_metadata << { key:, value:, source:,
                           last_updated: metadata_provenance[key]['updated_at'] }
    end
    sample_metadata
  end
end
