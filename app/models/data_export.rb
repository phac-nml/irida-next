# frozen_string_literal: true

# entity class for DataExport
class DataExport < ApplicationRecord
  has_logidze
  broadcasts_refreshes

  belongs_to :user

  after_commit { broadcast_refresh_to [user, :data_exports] }

  has_one_attached :file, dependent: :purge_later

  validates :status, presence: true, acceptance: { accept: %w[processing ready] }
  validates :export_type, presence: true, acceptance: { accept: %w[sample analysis linelist] }
  validates :export_parameters, presence: true

  validate :validate_export_parameters

  ransacker :id do
    Arel.sql('id::varchar')
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name export_type status created_at expires_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
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
      validate_linelist_export_parameters
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
      unless %w[project user].include?(export_parameters['analysis_type'])
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
