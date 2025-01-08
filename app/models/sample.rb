# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include MetadataSortable
  include HasPuid
  include History
  include FileSelector

  extend Pagy::Searchkick

  has_logidze
  acts_as_paranoid

  searchkick \
    merge_mappings: true,
    mappings: {
      dynamic_templates: [
        {
          string_template: {
            match: '*',
            match_mapping_type: 'string',
            path_unmatch: 'metadata.*',
            mapping: {
              fields: {
                analyzed: {
                  analyzer: 'searchkick_index',
                  index: true,
                  type: 'text'
                }
              },
              ignore_above: 30_000,
              type: 'keyword'
            }
          }
        },
        {
          metadata_dates: {
            path_match: 'metadata.*_date',
            mapping: {
              type: 'date',
              ignore_malformed: true
            }
          }
        }, {
          metadata_non_dates: {
            path_match: 'metadata.*',
            path_unmatch: 'metadata.*_date',
            mapping: {
              type: 'keyword',
              fields: {
                numeric: {
                  type: 'double',
                  ignore_malformed: true
                }
              }
            }
          }
        }
      ]
    },
    deep_paging: true,
    text_middle: %i[name puid]

  belongs_to :project, counter_cache: true

  broadcasts_refreshes_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  scope :sort_by_attachments_updated_at_nulls_last_asc,
        -> { order('attachments_updated_at ASC NULLS LAST') }

  scope :sort_by_attachments_updated_at_nulls_last_desc,
        -> { order('attachments_updated_at DESC NULLS LAST') }

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: :project_id }

  def self.model_prefix
    'SAM'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id puid name metadata created_at updated_at attachments_updated_at]
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

  def search_data
    {
      name: name,
      puid: puid,
      project_id: project_id,
      metadata: metadata.transform_keys { |k| k.gsub('.', '___') },
      created_at: created_at,
      updated_at: updated_at,
      attachments_updated_at: attachments_updated_at
    }.compact
  end

  def field?(field)
    metadata.key?(field)
  end

  def updatable_field?(field)
    return true unless metadata_provenance.key?(field)

    metadata_provenance[field]['source'] == 'user'
  end

  def should_index?
    !deleted?
  end
end
