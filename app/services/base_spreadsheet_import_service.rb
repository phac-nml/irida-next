# frozen_string_literal: true

require 'roo'

# Service base class for handling spreadsheet file imports
class BaseSpreadsheetImportService < BaseService
  FileImportError = Class.new(StandardError)

  def initialize(namespace, user = nil, blob_id = nil, required_headers = [], minimum_additional_data_columns = 0, params = {}) # rubocop:disable Metrics/ParameterLists,Layout/LineLength
    super(user, params)
    @namespace = namespace
    @file = ActiveStorage::Blob.find(blob_id)
    @required_headers = required_headers
    @minimum_additional_data_columns = minimum_additional_data_columns
    @spreadsheet = nil
    @headers = nil
    @temp_import_file = Tempfile.new
  end

  def execute
    raise NotImplementedError
  end

  protected

  def validate_file
    extension = validate_file_extension
    download_batch_import_file(extension)

    @headers = @spreadsheet.row(1).compact
    validate_file_headers

    validate_file_rows
  end

  def validate_file_extension
    file_extension = File.extname(@file.filename.to_s).downcase

    return file_extension if %w[.csv .tsv .xls .xlsx].include?(file_extension)

    raise FileImportError, I18n.t('services.spreadsheet_import.invalid_file_extension')
  end

  def download_batch_import_file(extension)
    begin
      @temp_import_file.binmode
      @file.download do |chunk|
        @temp_import_file.write(chunk)
      end
    ensure
      @temp_import_file.close
    end
    @spreadsheet = if extension.eql? '.tsv'
                     Roo::Spreadsheet.open(@temp_import_file.path,
                                           { extension: '.csv', csv_options: { col_sep: "\t" } })
                   else
                     Roo::Spreadsheet.open(@temp_import_file.path, extension:)
                   end
  end

  def validate_file_headers
    duplicate_headers = @headers.find_all { |header| @headers.count(header) > 1 }.uniq
    unless duplicate_headers.empty?
      raise FileImportError,
            I18n.t('services.spreadsheet_import.duplicate_column_names')
    end

    missing_headers = @required_headers - @headers
    unless missing_headers.empty?
      raise FileImportError, I18n.t('services.spreadsheet_import.missing_header',
                                    header_title: missing_headers.join(','))
    end

    return unless @headers.count < (@required_headers.count + @minimum_additional_data_columns)

    raise FileImportError, I18n.t('services.spreadsheet_import.missing_data_columns')
  end

  def validate_file_rows
    # Should have at least 2 rows
    first_row = @spreadsheet.row(2)
    return unless first_row.compact.empty?

    raise FileImportError, I18n.t('services.spreadsheet_import.missing_data_row')
  end

  def perform_file_import
    raise NotImplementedError
  end

  def cleanup_files
    # delete the blob and temporary file as we no longer require them
    @file.purge
    @temp_import_file.unlink
  end
end
