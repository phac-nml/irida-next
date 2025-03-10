# frozen_string_literal: true

# SpreadsheetHelper module provides utility methods to read and parse Excel and CSV files.
# Supported formats: .xlsx, .xls, and .csv. Numeric strings are automatically converted to numbers.
module SpreadsheetHelper
  SUPPORTED_FORMATS = %w[.xlsx .xls .csv].freeze

  # Custom exception used when errors occur during Excel parsing.
  class SpreadsheetParsingError < StandardError; end

  # Parses an Excel/CSV file and returns its contents as an array.
  # @param file [ActionDispatch::Http::UploadedFile] the file to be parsed.
  # @return [Array<Hash>] an array with the first element as headers and subsequent elements as row hashes.
  # @raise [SpreadsheetParsingError] if the file is missing or headers cannot be extracted.
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

  # Opens the file as a spreadsheet using Roo, based on its file extension.
  # @param path [String] the full file path.
  # @param file_extension [String] the file extension.
  # @return [Roo::Spreadsheet] the spreadsheet instance.
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

  # Extracts the header row from the spreadsheet.
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet to read.
  # @return [Array<String>] an array of header names.
  # @raise [SpreadsheetParsingError] if the header row is empty.
  def extract_headers(spreadsheet)
    headers = spreadsheet.row(1).map(&:presence).compact
    raise SpreadsheetParsingError, t('spreadsheet_helper.no_headers') if headers.empty?

    headers
  end

  # Extracts row data from the spreadsheet and maps each row to a header.
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet to parse.
  # @param headers [Array<String>] an array of header names.
  # @return [Array<Hash>] array of hashes representing the rows.
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

  # Converts numeric string values to Integer or Float.
  # @param val [Object] the value from a cell.
  # @return [Integer, Float, Object] the numeric conversion or the original value.
  def convert_numeric(val)
    if val.to_s.match?(/\A\d+\z/)
      val.to_i
    elsif val.to_s.match?(/\A\d*\.\d+\z/)
      val.to_f
    else
      val
    end
  end

  # Logs Roo-specific errors and raises a custom SpreadsheetParsingError.
  # @param error [Roo::Error] the encountered Roo exception.
  # @raise [SpreadsheetParsingError] with details of the Roo error.
  def handle_roo_error(error)
    Rails.logger.error "Spreadsheet parsing error: #{error.message}"
    raise SpreadsheetParsingError, t('spreadsheet_helper.failed_parsing', error: error.message)
  end

  # Logs general errors during parsing and raises a custom SpreadsheetParsingError.
  # @param error [StandardError] the encountered exception.
  # @raise [SpreadsheetParsingError] containing the error message and backtrace.
  def handle_standard_error(error)
    Rails.logger.error t('spreadsheet_helper.unexpected_error', error: "#{error.class} - #{error.message}")
    Rails.logger.error error.backtrace.join("\n")
    raise SpreadsheetParsingError, t('spreadsheet_helper.unexpected_error', error: error.message)
  end
end
