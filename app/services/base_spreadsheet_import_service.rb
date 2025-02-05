# frozen_string_literal: true

require 'roo'

# Service base class for handling spreadsheet file imports
class BaseSpreadsheetImportService < BaseService
  FileImportError = Class.new(StandardError)

  def initialize(namespace, user = nil, blob_id = nil, required_headers = [], params = {}) # rubocop:disable Metrics/ParameterLists
    super(user, params)
    @namespace = namespace
    @file = ActiveStorage::Blob.find(blob_id)
    @required_headers = required_headers
    @spreadsheet = nil
    @headers = nil
    @temp_import_file = Tempfile.new
  end

  def execute
    validate_required_columns

    validate_file

    perform_file_import
  rescue FileImportError => e
    @namespace.errors.add(:base, e.message)
    {}
  end

  protected

  def validate_required_columns
    @required_headers.each do |header|
      raise FileImportError, I18n.t('services.samples.metadata.import_file.empty_sample_id_column') if header.nil? # TODO: text
    end
  end

  def validate_file
    if @file.nil?
      raise FileImportError,
            I18n.t('services.samples.batch_import.empty_file') # TODO: text
    end

    extension = validate_file_extension
    download_batch_import_file(extension)

    @headers = @spreadsheet.row(1).compact
    validate_file_headers

    validate_file_rows
  end

  def validate_file_extension
    file_extension = File.extname(@file.filename.to_s).downcase

    return file_extension if %w[.csv .tsv .xls .xlsx].include?(file_extension)

    raise SampleFileImportError,
          I18n.t('services.samples.metadata.import_file.invalid_file_extension') # TODO: text
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
                      Roo::CSV.new(@temp_import_file, extension:, csv_options: { col_sep: "\t" })
                    else
                      Roo::Spreadsheet.open(@temp_import_file.path, extension:)
                    end
  end

  def validate_file_headers
    duplicate_headers = @headers.find_all { |header| @headers.count(header) > 1 }.uniq
    unless duplicate_headers.empty?
      raise SampleFileImportError,
            I18n.t('services.sammple.batch_import.duplicate_column_names') # TODO: text
    end

    @required_headers.each do |req_header|
      unless @headers.include?(req_header)
        raise FileImportError, I18n.t('services.samples.batch_import.missing_header', header_title: req_header) # TODO: text
      end
    end
  end

  def validate_file_rows
    # Should have at least 2 rows
    first_row = @spreadsheet.row(2)
    return unless first_row.compact.empty?

    raise FileImportError, I18n.t('services.samples.batch_import.missing_data_row') # TODO: text
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
