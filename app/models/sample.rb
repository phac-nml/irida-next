# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  include History

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

  def self.metadata_sort(field, dir)
    metadata_field = Arel::Nodes::InfixOperation.new(
      '->',
      Sample.arel_table[:metadata],
      Arel::Nodes.build_quoted(URI.decode_www_form_component(field))
    )

    if dir.to_sym == :asc
      metadata_field.asc
    else
      metadata_field.desc
    end
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
end
