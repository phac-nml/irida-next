# frozen_string_literal: true

# entity class for DataExport
class DataExport < ApplicationRecord
  has_logidze

  belongs_to :user

  has_one_attached :file, dependent: :purge_later

  validates :status, presence: true, acceptance: { accept: %w[processing ready] }
  validates :export_type, presence: true, acceptance: { accept: %w[sample analysis linelist] }
  validates :export_parameters, presence: true

  validate :validate_export_parameters

  private

  def validate_export_parameters
    unless export_parameters.key?('ids')
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_ids'))
    end

    validate_attachment_formats if export_type == 'sample' && export_parameters.key?('attachment_formats')
    validate_namespace_id unless export_type == 'analysis'
    validate_linelist_export_parameters if export_type == 'linelist'
  end

  def validate_attachment_formats
    invalid_formats = export_parameters['attachment_formats'] - Attachment::FORMAT_REGEX.keys

    return if invalid_formats.empty?

    errors.add(:export_parameters,
               I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
                      invalid_formats: invalid_formats.join(', ')))
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

  def validate_linelist_export_parameters
    unless export_parameters.key?('metadata_fields')
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_metadata_fields'))
    end

    validate_linelist_format
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
end
