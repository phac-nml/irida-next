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
    validate_linelist_export_parameters if export_type == 'linelist'
  end

  def validate_linelist_export_parameters
    unless export_parameters.key?('metadata_fields')
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_metadata_fields'))
    end

    validate_linelist_format

    validate_linelist_namespace_type
  end

  def validate_linelist_format
    if export_parameters.key?('format')
      return if %w[xlsx csv].include?(export_parameters['format'])

      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'))
    else
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_file_format'))
    end
  end

  def validate_linelist_namespace_type
    if export_parameters.key?('namespace_type')
      return if [Namespaces::ProjectNamespace.sti_name, Group.sti_name].include?(export_parameters['namespace_type'])

      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_type'))
    else
      errors.add(:export_parameters,
                 I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_type'))
    end
  end
end
