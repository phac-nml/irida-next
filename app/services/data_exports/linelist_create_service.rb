# frozen_string_literal: true

module DataExports
  # Creates a ready linelist data export from a direct-uploaded Active Storage blob.
  class LinelistCreateService < BaseService # rubocop:disable Metrics/ClassLength
    class DataExportCreateError < StandardError
    end

    def execute
      @data_export = DataExport.new(data_export_attributes)

      if @data_export.valid?
        validate_sample_ids
        attach_blob if @data_export.errors.empty?
      end

      @data_export
    rescue DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    def data_export_attributes
      {
        name: normalized_name,
        export_type: 'linelist',
        status: 'ready',
        export_parameters: export_parameters,
        user: current_user,
        expires_at: ApplicationController.helpers.add_business_days(DateTime.current, 3)
      }
    end

    def export_parameters
      {
        'ids' => sample_ids,
        'metadata_fields' => metadata_fields,
        'namespace_id' => namespace_id,
        'linelist_format' => linelist_format
      }
    end

    def normalized_name
      name = params['name'].to_s.strip
      name.presence
    end

    def namespace_id
      params['namespace_id']
    end

    def linelist_format
      params['linelist_format']
    end

    def sample_ids
      Array(params['sample_ids']).compact_blank
    end

    def metadata_fields
      Array(params['metadata_fields']).compact_blank
    end

    def signed_blob_id
      params['signed_blob_id']
    end

    def validate_sample_ids
      namespace = Namespace.find(namespace_id)

      authorize! namespace, to: :export_data?

      return unless authorized_export_samples(namespace, sample_ids).count != sample_ids.count

      raise DataExportCreateError, I18n.t('services.data_exports.create.invalid_export_samples')
    rescue ActiveRecord::RecordNotFound
      raise DataExportCreateError,
            I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id')
    end

    def authorized_export_samples(namespace, selected_ids)
      authorized_scope(Sample, type: :relation, as: :namespace_samples,
                               scope_options: { namespace:, minimum_access_level: Member::AccessLevel::ANALYST })
        .where(id: selected_ids)
    end

    def attach_blob
      blob = direct_upload_blob
      validate_blob!(blob)

      DataExport.transaction do
        @data_export.save!
        blob.update!(
          filename: "#{@data_export.id}.#{linelist_format}",
          content_type: content_type_for_attachment
        )
        @data_export.file.attach(blob)
        validate_attachment!
      end
    rescue ActiveStorage::FileNotFoundError
      raise DataExportCreateError, I18n.t('services.data_exports.linelist_create.missing_blob_file')
    rescue ActiveRecord::RecordInvalid => e
      raise DataExportCreateError, e.record.errors.full_messages.to_sentence
    end

    def direct_upload_blob
      ActiveStorage::Blob.find_signed!(signed_blob_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound, ArgumentError
      raise DataExportCreateError, I18n.t('services.data_exports.linelist_create.invalid_signed_blob_id')
    end

    def validate_blob!(blob)
      validate_linelist_format!
      validate_blob_size!(blob)
      validate_blob_content_type!(blob)
    end

    def validate_linelist_format!
      return if DataExports::UploadFileValidator::CONTENT_TYPES_BY_FORMAT.key?(linelist_format)

      raise DataExportCreateError,
            I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format')
    end

    def validate_blob_size!(blob)
      return if blob.byte_size.to_i <= DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES

      raise DataExportCreateError,
            I18n.t('services.data_exports.upload.file_too_large',
                   max_mb: DataExports::UploadFileValidator::MAX_UPLOAD_SIZE_BYTES / 1.megabyte)
    end

    def validate_blob_content_type!(blob)
      allowed_content_types = DataExports::UploadFileValidator::CONTENT_TYPES_BY_FORMAT.fetch(linelist_format)
      detected_content_type = detected_mime_type(blob).presence
      reported_content_type = blob.content_type.to_s.presence
      content_type = detected_content_type || reported_content_type

      return if content_type.present? && allowed_content_types.include?(content_type)

      raise DataExportCreateError,
            I18n.t('services.data_exports.upload.invalid_file_type', file_format: linelist_format.upcase)
    end

    def detected_mime_type(blob)
      blob.open do |file|
        Marcel::MimeType.for(file, name: blob.filename.to_s)
      end
    end

    def content_type_for_attachment
      DataExports::UploadFileValidator::CONTENT_TYPES_BY_FORMAT.fetch(linelist_format).first
    end

    def validate_attachment!
      return if @data_export.file.attached?

      raise DataExportCreateError, I18n.t('services.data_exports.upload.attach_failed')
    end
  end
end
