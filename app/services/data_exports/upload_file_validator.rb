# frozen_string_literal: true

module DataExports
  # Validates uploaded linelist files before they are attached.
  class UploadFileValidator
    class UploadValidationError < StandardError
    end

    MAX_UPLOAD_SIZE_BYTES = 25.megabytes
    CONTENT_TYPES_BY_FORMAT = {
      'csv' => ['text/csv', 'text/plain', 'application/csv', 'application/vnd.ms-excel'],
      'xlsx' => ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
    }.freeze

    def initialize(file:, linelist_format:)
      @file = file
      @linelist_format = linelist_format
    end

    def validate!
      validate_linelist_format!
      validate_file_size!
      validate_file_content_type!
    end

    def content_type_for_attachment
      CONTENT_TYPES_BY_FORMAT.fetch(@linelist_format).first
    end

    private

    def validate_linelist_format!
      return if CONTENT_TYPES_BY_FORMAT.key?(@linelist_format)

      raise UploadValidationError,
            I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format')
    end

    def validate_file_size!
      return if @file.size.to_i <= MAX_UPLOAD_SIZE_BYTES

      raise UploadValidationError,
            I18n.t('services.data_exports.upload.file_too_large', max_mb: MAX_UPLOAD_SIZE_BYTES / 1.megabyte)
    end

    def validate_file_content_type!
      allowed_content_types = CONTENT_TYPES_BY_FORMAT.fetch(@linelist_format)
      detected_content_type = detected_mime_type
      reported_content_type = @file.content_type.to_s.presence

      return if [detected_content_type, reported_content_type].compact.any? do |content_type|
        allowed_content_types.include?(content_type)
      end

      raise UploadValidationError,
            I18n.t('services.data_exports.upload.invalid_file_type', file_format: @linelist_format.upcase)
    end

    def detected_mime_type
      Marcel::MimeType.for(@file.tempfile, name: @file.original_filename)
    ensure
      @file.tempfile.rewind
    end
  end
end
