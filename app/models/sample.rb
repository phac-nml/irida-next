# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include MetadataSortable
  include HasPuid
  include History

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

  def sorted_files
    return {} if attachments.empty?

    @sorted_files || sort_files
  end

  def sort_files
    singles = []
    pe_forward = []
    pe_reverse = []

    attachments.each do |attachment|
        item = { filename: attachment.file.filename.to_s,
                global_id: attachment.to_global_id,
                id: attachment.id,
                byte_size: attachment.byte_size,
                created_at: attachment.created_at
              }
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

  def samplesheet_fastq_files(property, workflow_params)
    direction = get_fastq_direction(property)
    pattern = Irida::Pipelines.instance.find_pipeline_by(workflow_params[:name], workflow_params[:version]).property_pattern(property)
    singles = filter_files_by_pattern(sorted_files[:singles] || [],
                                        pattern || "/^\S+.f(ast)?q(.gz)?$/")
    files = []
    if sorted_files[direction].present?
      files = sorted_files[direction] || []
      files.concat(singles) unless pe_only?(property)
    else
      files = singles
    end
    files = order_files(files)
    files
  end

  def most_recent_file(file_type, **system_arguments)
    if file_type == 'fastq'
      most_recent_fastq_file(system_arguments[:property], system_arguments[:workflow_params])
    elsif file_type == 'other'
      most_recent_other_file(system_arguments[:autopopulate], system_arguments[:pattern])
    end
  end

  # separate function from samplesheet_fastq_files since this function would prefer selection of latest paired_end
  # attachments, where as samplesheet_fastq_files will return the overall latest attachment (ie: possibly a single)
  def most_recent_fastq_file(property, workflow_params)
    direction = get_fastq_direction(property)

    if sorted_files[direction].present?
      sorted_files[direction].last
    else
      pattern = Irida::Pipelines.instance.find_pipeline_by(workflow_params[:name], workflow_params[:version]).property_pattern(property)
      last_single = filter_files_by_pattern(sorted_files[:singles] || [],
                                        pattern || "/^\S+.f(ast)?q(.gz)?$/").last
      last_single.nil? ? {} : last_single
    end
  end

  def most_recent_other_file(autopopulate, pattern)
    return {} unless autopopulate

    files = if pattern
              filter_files_by_pattern(sorted_files[:singles] || [], pattern)
            else
              sorted_files[:singles] || []
            end
    files = order_files(files)
    files.present? ? files.last : {}
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

  def filter_files_by_pattern(files, pattern)
    files.select { |file| file[:filename] =~ Regexp.new(pattern) }
  end

  private

  def get_fastq_direction(property)
    property.match(/fastq_(\d+)/)[1].to_i == 1 ? :pe_forward : :pe_reverse
  end

  def pe_only?(property)
    property['pe_only'].present?
  end

  def order_files(files)
    (files.sort_by! {|file| file[:created_at]}).reverse
    files
  end
end
