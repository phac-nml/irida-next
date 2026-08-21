# frozen_string_literal: true

# entity class for DataExport
class DataExport < ApplicationRecord # rubocop:disable Metrics/ClassLength
  has_logidze
  broadcasts_refreshes

  belongs_to :user

  after_commit { broadcast_refresh_to [user, :data_exports] }

  has_one_attached :file, dependent: :purge_later

  # Used by CreateService so authorization can run before the source-size query.
  attr_accessor :skip_source_size_validation

  validates :status, presence: true, acceptance: { accept: %w[processing ready] }
  validates :export_type, presence: true, acceptance: { accept: %w[sample analysis linelist] }
  validates :export_parameters, presence: true

  validate :validate_export_parameters
  validate :validate_source_size, on: :create, if: :validate_source_size?

  ransacker :id do
    Arel.sql('id::varchar')
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name export_type status created_at expires_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.icon
    :export
  end

  # Source-file byte total for limit checks, without downloading files.
  def source_size_bytes
    case export_type
    when 'sample'
      sample_export_source_size
    when 'analysis'
      analysis_export_source_size
    else
      0
    end
  end

  private

  def validate_export_parameters
    if !export_parameters.key?('ids') || (export_parameters.key?('ids') && export_parameters['ids'].empty?)
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_ids'))
    end

    validate_export_type_specific_params

    validate_namespace_id unless export_type == 'analysis' && export_parameters['analysis_type'] == 'user'
  end

  def validate_export_type_specific_params
    case export_type
    when 'sample'
      validate_attachment_formats
    when 'analysis'
      validate_analysis_type
    when 'linelist'
      validate_linelist_format
    end
  end

  def validate_attachment_formats
    if export_parameters.key?('attachment_formats')
      invalid_formats = export_parameters['attachment_formats'] - Attachment::FORMAT_REGEX.keys

      return nil if invalid_formats.empty?

      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
                        invalid_formats: invalid_formats.join(', ')))
    else
      errors.add(:export_parameters,
                 I18n.t(
                   'activerecord.errors.models.data_export.attributes.export_parameters.missing_attachment_formats'
                 ))
    end
  end

  def validate_analysis_type
    if export_parameters.key?('analysis_type')
      unless %w[group project user].include?(export_parameters['analysis_type'])
        errors.add(:export_parameters,
                   I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_analysis_type'))
      end
    else
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_analysis_type'))
    end
  end

  def validate_namespace_id
    if export_parameters.key?('namespace_id')
      namespace = Namespace.find_by(id: export_parameters['namespace_id'])
      if namespace.nil?
        errors.add(:export_parameters,
                   I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id'))
      end
    else
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_id'))
    end
  end

  def validate_linelist_format
    if export_parameters.key?('linelist_format')
      return if %w[xlsx csv].include?(export_parameters['linelist_format'])

      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'))
    else
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_file_format'))
    end
  end

  def validate_source_size?
    return false if skip_source_size_validation
    return false if export_type.blank? || export_type == 'linelist' || export_parameters.blank?

    errors.empty?
  end

  def validate_source_size
    max_data_export_size_gigabytes = Irida::CurrentSettings.max_data_export_size_gigabytes

    return if source_size_bytes < max_data_export_size_gigabytes.gigabytes

    errors.add(
      :base,
      :max_data_export_size_exceeded,
      message: I18n.t(
        'services.data_exports.create.max_data_export_size_exceeded',
        max_size_gigabytes: max_data_export_size_gigabytes
      )
    )
  end

  def sample_export_source_size
    sample_attachment_scope.sum('active_storage_blobs.byte_size')
  end

  def analysis_export_source_size
    workflow_execution_output_scope.sum('active_storage_blobs.byte_size') +
      sample_workflow_execution_output_scope.sum('active_storage_blobs.byte_size')
  end

  def sample_attachment_scope
    scope = attachments_scope.where(
      attachable_type: 'Sample',
      attachable_id: selected_ids
    )

    return scope if all_attachment_formats_selected?

    scope.where("attachments.metadata ->> 'format' IN (?)", selected_attachment_formats)
  end

  def all_attachment_formats_selected?
    (Attachment::FORMAT_REGEX.keys - selected_attachment_formats).empty?
  end

  def workflow_execution_output_scope
    attachments_scope.where(
      attachable_type: 'WorkflowExecution',
      attachable_id: selected_ids
    )
  end

  def sample_workflow_execution_output_scope
    attachments_scope.where(
      attachable_type: 'SamplesWorkflowExecution',
      attachable_id: SamplesWorkflowExecution.where(workflow_execution_id: selected_ids).select(:id)
    )
  end

  def attachments_scope
    Attachment.joins(:file_blob)
  end

  def selected_ids
    Array((export_parameters || {})['ids'])
  end

  def selected_attachment_formats
    Array((export_parameters || {})['attachment_formats'])
  end
end
