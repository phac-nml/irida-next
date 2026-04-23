# frozen_string_literal: true

module DataExports
  # Service used to save a client-generated linelist export to the server.
  class UploadService < BaseService
    class DataExportUploadError < StandardError
    end

    def execute
      @data_export = DataExport.new(upload_attributes)

      if @data_export.valid?
        validate_sample_ids
        attach_upload if @data_export.errors.empty?
      end

      @data_export
    rescue DataExports::UploadService::DataExportUploadError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    def upload_attributes
      {
        name: normalized_name,
        export_type: 'linelist',
        status: 'ready',
        export_parameters: upload_export_parameters,
        user: current_user,
        expires_at: ApplicationController.helpers.add_business_days(DateTime.current, 3)
      }
    end

    def upload_export_parameters
      {
        'ids' => sample_ids,
        'metadata_fields' => metadata_fields,
        'namespace_id' => namespace_id,
        'linelist_format' => linelist_format
      }
    end

    def namespace_id
      params.dig('export_parameters', 'namespace_id')
    end

    def linelist_format
      params.dig('export_parameters', 'linelist_format')
    end

    def sample_ids
      Array(params.dig('export_parameters', 'ids')).compact_blank
    end

    def metadata_fields
      Array(params.dig('export_parameters', 'metadata_fields')).compact_blank
    end

    def normalized_name
      name = params['name'].to_s.strip
      name.presence
    end

    def validate_sample_ids
      namespace = Namespace.find(namespace_id)

      authorize! namespace, to: :export_data?

      return unless authorized_export_samples(namespace, sample_ids).count != sample_ids.count

      raise DataExportUploadError, I18n.t('services.data_exports.create.invalid_export_samples')
    rescue ActiveRecord::RecordNotFound
      raise DataExportUploadError,
            I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id')
    end

    def authorized_export_samples(namespace, selected_ids)
      authorized_scope(Sample, type: :relation, as: :namespace_samples,
                               scope_options: { namespace:, minimum_access_level: Member::AccessLevel::ANALYST })
        .where(id: selected_ids)
    end

    def attach_upload
      file = uploaded_file
      file_validator = UploadFileValidator.new(file:, linelist_format:)
      file_validator.validate!

      @data_export.save!
      attach_file(file, file_validator.content_type_for_attachment)
      validate_attachment!
    rescue UploadFileValidator::UploadValidationError => e
      raise DataExportUploadError, e.message
    rescue ActiveRecord::RecordInvalid => e
      raise DataExportUploadError, e.record.errors.full_messages.to_sentence
    end

    def uploaded_file
      file = params['file']
      return file if file.respond_to?(:tempfile)

      raise DataExportUploadError, I18n.t('services.data_exports.upload.missing_file')
    end

    def attach_file(file, content_type)
      @data_export.file.attach(
        io: file.tempfile,
        filename: "#{@data_export.id}.#{linelist_format}",
        content_type: content_type
      )
    end

    def validate_attachment!
      return if @data_export.file.attached?

      raise DataExportUploadError, I18n.t('services.data_exports.upload.attach_failed')
    end
  end
end
