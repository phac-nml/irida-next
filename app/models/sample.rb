# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  include MetadataSortable

  include History

  has_logidze
  acts_as_paranoid

  include HasPuid

  belongs_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  scope :sort_by_attachments_updated_at_nulls_last_asc,
        -> { order('attachments_updated_at ASC NULLS LAST') }

  scope :sort_by_attachments_updated_at_nulls_last_desc,
        -> { order('attachments_updated_at DESC NULLS LAST') }

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[project_id] }

  def self.model_prefix
    'SAM'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id puid name created_at updated_at attachments_updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def metadata_with_provenance
    sample_metadata = []
    metadata.each do |key, value|
      source_type = metadata_provenance[key]['source']
      source = if source_type == 'user'
                 User.find(metadata_provenance[key]['id']).email
               else
                 "#{I18n.t('models.sample.analysis')} #{metadata_provenance[key]['id']}"
               end
      sample_metadata << { key:, value:, source:, source_type:,
                           last_updated: metadata_provenance[key]['updated_at'] }
    end
    sample_metadata
  end

  def sorted_files
    return {} if attachments.empty?

    @sorted_files || sort_files
  end

  def sort_files
    singles = []
    pe_forward = []
    pe_reverse = []

    attachments.each do |attachment|
      item = [attachment.file.filename.to_s, attachment.to_global_id, { 'data-puid': attachment.puid }]
      case attachment.metadata['direction']
      when nil
        singles << item
      when 'forward'
        pe_forward << item
      else
        pe_reverse << item
      end
    end

    { singles:, pe_forward:, pe_reverse: }
  end
end
