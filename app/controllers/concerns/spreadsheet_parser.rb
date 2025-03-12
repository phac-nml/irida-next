# frozen_string_literal: true

# 📊 SpreadsheetParser module provides utility methods to read and parse Excel and CSV files.
# 🔍 Supported formats: .xlsx, .xls, and .csv
# 🔢 Automatically converts numeric strings to their proper number types
module SpreadsheetParser
  SUPPORTED_FORMATS = %w[.xlsx .xls .csv].freeze

  # ⚠️ Custom exception for spreadsheet parsing failures
  class SpreadsheetParsingError < StandardError; end

  # 📝 Parses an Excel/CSV file and returns its contents as structured data
  # @param file [ActionDispatch::Http::UploadedFile] the uploaded file to parse
  # @return [Array<Hash>] array of row data with headers as keys
  # @raise [SpreadsheetParsingError] if file is missing or invalid
  def parse_spreadsheet(file)
    raise SpreadsheetParsingError, t('spreadsheet_helper.no_file') unless file.present?

    extension = File.extname(file.filename.to_s).downcase
    data = []
    file.open do |f|
      spreadsheet = open_spreadsheet(f.path, extension)
      headers = extract_headers(spreadsheet)
      data << headers
      data.concat(extract_data(spreadsheet, headers))
    end

    data
  rescue Roo::Error => e
    Rails.logger.error "Spreadsheet parsing error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error t('spreadsheet_helper.unexpected_error', error: "#{e.class} - #{e.message}")
    Rails.logger.error e.backtrace.join("\n")
    raise SpreadsheetParsingError, t('spreadsheet_helper.unexpected_error', error: e.message)
  end

  private

  # 📂 Opens a spreadsheet file using the appropriate Roo class based on file extension
  # @param path [String] the full file path
  # @param file_extension [String] the lowercase file extension (e.g., '.xlsx')
  # @return [Roo::Spreadsheet] the spreadsheet object ready for reading
  # @raise [SpreadsheetParsingError] if file format is unsupported
  def open_spreadsheet(path, file_extension)
    case file_extension
    when '.csv'
      Roo::CSV.new(path)
    when '.xlsx'
      Roo::Excelx.new(path)
    when '.xls'
      Roo::Excel.new(path)
    else
      raise SpreadsheetParsingError, t('spreadsheet_helper.unknown_file_format', extension: file_extension)
    end
  end

  # 🏷️ Extracts the header row (first row) from the spreadsheet
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet to read
  # @return [Array<String>] array of column header names
  # @raise [SpreadsheetParsingError] if headers are missing or empty
  def extract_headers(spreadsheet)
    headers = spreadsheet.row(1).map(&:presence).compact
    raise SpreadsheetParsingError, t('spreadsheet_helper.no_headers') if headers.empty?

    headers
  end

  # 📋 Extracts all data rows from the spreadsheet and maps them to headers
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet to parse
  # @param headers [Array<String>] the column header names
  # @return [Array<Hash>] array of hashes where each hash represents a row
  def extract_data(spreadsheet, headers)
    data = []
    (2..spreadsheet.last_row).each do |i|
      row_data = spreadsheet.row(i)
      next unless row_data.any?(&:present?)

      row_data = row_data[0...headers.length]
      row_data = row_data.map { |val| convert_numeric(val) }
      data << headers.zip(row_data).to_h
    end
    data
  end

  # 🔢 Smart conversion of string values to appropriate number types
  # @param val [Object] the cell value to convert
  # @return [Integer, Float, Object] converted number or original value
  def convert_numeric(val)
    if val.to_s.match?(/\A\d+\z/)
      val.to_i
    elsif val.to_s.match?(/\A\d*\.\d+\z/)
      val.to_f
    else
      val
    end
  end

  # 🐞 Handles Roo-specific errors during spreadsheet processing
  # @param error [Roo::Error] the Roo exception that occurred
  # @raise [SpreadsheetParsingError] with friendly error message
  def handle_roo_error(error)
    Rails.logger.error "Spreadsheet parsing error: #{error.message}"
    raise SpreadsheetParsingError, t('spreadsheet_helper.failed_parsing', error: error.message)
  end

  # 🚨 Handles general errors during spreadsheet processing
  # @param error [StandardError] the exception that occurred
  # @raise [SpreadsheetParsingError] with user-friendly error message
  def handle_standard_error(error)
    Rails.logger.error t('spreadsheet_helper.unexpected_error', error: "#{error.class} - #{error.message}")
    Rails.logger.error error.backtrace.join("\n")
    raise SpreadsheetParsingError, t('spreadsheet_helper.unexpected_error', error: error.message)
  end
end
