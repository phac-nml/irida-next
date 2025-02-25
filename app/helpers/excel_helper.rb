# frozen_string_literal: true

# ExcelHelper is a helper module that provides methods for parsing Excel files.
# It supports .xlsx, .xls, and .csv formats.
module ExcelHelper
  SUPPORTED_FORMATS = %w[.xlsx .xls .csv].freeze

  # Custom error class for Excel parsing errors
  class ExcelParsingError < StandardError; end

  # Parses an Excel file and returns the data as an array of hashes.
  # @param file [ActionDispatch::Http::UploadedFile] the uploaded file to parse
  # @return [Array<Hash>] the parsed data
  # @raise [ExcelParsingError] if the file is blank or headers are missing
  def parse_excel_file(file)
    raise ExcelParsingError, 'No file provided' if file.blank?

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
    handle_roo_error(e)
  rescue StandardError => e
    handle_standard_error(e)
  end

  private

  # Opens the spreadsheet using Roo::Spreadsheet
  # @param path [String] the file path
  # @param extension [String] the file extension
  # @return [Roo::Spreadsheet] the opened spreadsheet
  def open_spreadsheet(path, extension)
    case extension.downcase
    when '.csv'
      Roo::CSV.new(path)
    when '.xlsx'
      Roo::Excelx.new(path)
    when '.xls'
      Roo::Excel.new(path)
    else
      raise ExcelParsingError, 'Unknown file type'
    end
  end

  # Extracts headers from the first row of the spreadsheet
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet object
  # @return [Array<String>] the extracted headers
  # @raise [ExcelParsingError] if no headers are found
  def extract_headers(spreadsheet)
    headers = spreadsheet.row(1).map(&:presence).compact
    raise ExcelParsingError, 'No headers found in file' if headers.empty?

    headers
  end

  # Extracts data from the spreadsheet and maps it to the headers
  # @param spreadsheet [Roo::Spreadsheet] the spreadsheet object
  # @param headers [Array<String>] the headers
  # @return [Array<Hash>] the extracted data
  def extract_data(spreadsheet, headers)
    data = []
    (2..spreadsheet.last_row).each do |i|
      row_data = spreadsheet.row(i)
      next unless row_data.any?(&:present?)

      # Skip rows that have incomplete data
      next unless row_data.length >= headers.length && row_data[0...headers.length].all?(&:present?)

      # If row has more columns than headers, truncate the extra columns
      row_data = row_data[0...headers.length]

      # Convert numeric strings to numbers
      row_data = row_data.map do |val|
        if val.to_s.match?(/\A\d+\z/)
          val.to_i
        elsif val.to_s.match?(/\A\d*\.\d+\z/)
          val.to_f
        else
          val
        end
      end

      data << headers.zip(row_data).to_h
    end
    data
  end

  # Handles Roo::Error exceptions
  # @param error [Roo::Error] the error object
  # @raise [ExcelParsingError] with a custom error message
  def handle_roo_error(error)
    Rails.logger.error "Excel parsing error: #{error.message}"
    raise ExcelParsingError, "Failed to parse Excel file: #{error.message}"
  end

  # Handles StandardError exceptions
  # @param error [StandardError] the error object
  # @raise [ExcelParsingError] with a custom error message
  def handle_standard_error(error)
    Rails.logger.error "Unexpected error parsing Excel file: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    raise ExcelParsingError, "An unexpected error occurred while parsing the file: #{error.message}"
  end
end
